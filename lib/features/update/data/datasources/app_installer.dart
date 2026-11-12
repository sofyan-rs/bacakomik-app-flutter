import 'dart:async';
import 'dart:io';

import 'package:yoru/core/di/register_module.dart';
import 'package:yoru/features/update/data/datasources/linux_rpm_updater.dart';
import 'package:yoru/features/update/domain/entities/app_release.dart';
import 'package:yoru/features/update/domain/entities/update_progress.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:ota_update/ota_update.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

/// The installed app, and what installs a release over it.
abstract interface class AppInstaller {
  Future<String> installedVersion();

  /// See [AppRelease.assetFor].
  Future<List<String>> assetSuffixes();

  Stream<UpdateProgress> install(ReleaseAsset asset);
}

@module
abstract class AppInstallerModule {
  @lazySingleton
  AppInstaller installer(@Named(filesDio) Dio dio) => Platform.isAndroid
      ? OtaAppInstaller()
      : Platform.isIOS
      ? IosAppInstaller()
      : DesktopAppInstaller(dio);
}

Future<String> _installedVersion() async =>
    (await PackageInfo.fromPlatform()).version;

/// Android's package installer, via `ota_update`.
class OtaAppInstaller implements AppInstaller {
  @override
  Future<String> installedVersion() => _installedVersion();

  @override
  Future<List<String>> assetSuffixes() async {
    final abi = await OtaUpdate().getAbi();
    return [if (abi != null) '$abi.apk', 'universal.apk'];
  }

  @override
  Stream<UpdateProgress> install(ReleaseAsset asset) async* {
    // A new OtaUpdate per run: each instance replays its first stream.
    final events = OtaUpdate().execute(
      asset.url,
      destinationFilename: asset.name,
      sha256checksum: asset.sha256,
    );
    await for (final event in events) {
      switch (event.status) {
        case OtaStatus.DOWNLOADING:
          yield UpdateDownloading(int.tryParse(event.value ?? '') ?? 0);
        case OtaStatus.INSTALLING:
        case OtaStatus.INSTALLATION_DONE:
          yield const UpdateInstalling();
          return;
        case OtaStatus.CANCELED:
          return;
        case OtaStatus.ALREADY_RUNNING_ERROR:
        case OtaStatus.INSTALLATION_ERROR:
        case OtaStatus.PERMISSION_NOT_GRANTED_ERROR:
        case OtaStatus.INTERNAL_ERROR:
        case OtaStatus.DOWNLOAD_ERROR:
        case OtaStatus.CHECKSUM_ERROR:
          yield UpdateInstallFailed('${event.status.name}: ${event.value}');
          return;
      }
    }
  }
}

/// iOS: the IPA is sideloaded, so the app that signed it installs the
/// update. Opens AltStore or SideStore on `…-ios.ipa` when one is there
/// (`LSApplicationQueriesSchemes` in Info.plist), else the IPA in Safari
/// for Sideloadly and the like. The stream ends after the hand-off.
class IosAppInstaller implements AppInstaller {
  IosAppInstaller({
    Future<bool> Function(Uri)? canLaunch,
    Future<bool> Function(Uri)? launch,
  }) : _canLaunch = canLaunch ?? canLaunchUrl,
       _launch =
           launch ??
           ((uri) => launchUrl(uri, mode: LaunchMode.externalApplication));

  final Future<bool> Function(Uri) _canLaunch;
  final Future<bool> Function(Uri) _launch;

  /// URL schemes of the sideloading stores, in the order tried.
  static const stores = ['altstore', 'sidestore'];

  @override
  Future<String> installedVersion() => _installedVersion();

  @override
  Future<List<String>> assetSuffixes() async => ['ios.ipa'];

  @override
  Stream<UpdateProgress> install(ReleaseAsset asset) async* {
    for (final scheme in stores) {
      final uri = Uri(
        scheme: scheme,
        host: 'install',
        queryParameters: {'url': asset.url},
      );
      if (await _canLaunch(uri) && await _launch(uri)) {
        yield const UpdateInstalling();
        return;
      }
    }
    if (await _launch(Uri.parse(asset.url))) {
      yield const UpdateInstalling();
    } else {
      yield const UpdateInstallFailed('No app could open the IPA');
    }
  }
}

/// Desktop: downloads the release asset, then quits while a detached script
/// puts it in place of the running app and opens it again.
///
/// macOS takes `…-macos.zip` (the `.app`, replaced where it runs from),
/// Windows `…-windows-setup.exe` (run silently; it relaunches the app),
/// Linux takes `…-linux-x86_64.rpm` for RPM installs (DNF via polkit),
/// or `…-linux-x86_64.AppImage` (replaces the AppImage that runs).
class DesktopAppInstaller implements AppInstaller {
  DesktopAppInstaller(
    this._dio, {
    LinuxRpmUpdater? rpm,
    Future<Directory> Function()? temporaryDirectory,
  }) : _rpm = rpm ?? LinuxRpmUpdater(),
       _temporaryDirectory = temporaryDirectory ?? getTemporaryDirectory;

  final Dio _dio;
  final LinuxRpmUpdater _rpm;
  final Future<Directory> Function() _temporaryDirectory;

  @override
  Future<String> installedVersion() => _installedVersion();

  @override
  Future<List<String>> assetSuffixes() async => [
    if (Platform.isMacOS) 'macos.zip',
    if (Platform.isWindows) 'windows-setup.exe',
    if (Platform.isLinux)
      await _rpm.isInstalled() ? 'linux-x86_64.rpm' : 'linux-x86_64.AppImage',
  ];

  @override
  Stream<UpdateProgress> install(ReleaseAsset asset) async* {
    final isRpm = Platform.isLinux && await _rpm.isInstalled();
    final appImage = Platform.environment['APPIMAGE'];
    if (Platform.isLinux && !isRpm && (appImage == null || appImage.isEmpty)) {
      yield const UpdateInstallFailed('Not running from an AppImage or RPM');
      return;
    }
    // RPMs are installed as root, so a release digest is required before download.
    if (isRpm && asset.sha256 == null) {
      yield const UpdateInstallFailed('CHECKSUM_MISSING');
      return;
    }

    Directory? dir;
    try {
      dir = await (await _temporaryDirectory()).createTemp('yoru-update-');
      // Use a private directory and a fixed RPM name for the privileged installer.
      final file = File(
        '${dir.path}${Platform.pathSeparator}${isRpm ? 'update.rpm' : asset.name}',
      );
      await for (final progress in _downloadAndInstall(
        asset,
        file,
        dir,
        appImage,
        isRpm,
      )) {
        yield progress;
      }
    } on ProcessException catch (e) {
      yield UpdateInstallFailed('INSTALLATION_ERROR: ${e.message}');
    } on FileSystemException catch (e) {
      yield UpdateInstallFailed('FILE_ERROR: ${e.message}');
    } finally {
      if (dir != null && await dir.exists()) await dir.delete(recursive: true);
    }
  }

  Stream<UpdateProgress> _downloadAndInstall(
    ReleaseAsset asset,
    File file,
    Directory dir,
    String? appImage,
    bool isRpm,
  ) async* {
    final progress = StreamController<int>();
    final download = _dio
        .download(
          asset.url,
          file.path,
          onReceiveProgress: (received, total) {
            if (total > 0) progress.add(received * 100 ~/ total);
          },
        )
        // Handle the download error immediately, even before progress is read.
        .then<Object?>((_) => null, onError: (Object error) => error)
        .whenComplete(progress.close);
    yield const UpdateDownloading(0);
    await for (final percent in progress.stream) {
      yield UpdateDownloading(percent);
    }
    final downloadError = await download;
    if (downloadError != null) {
      yield UpdateInstallFailed('DOWNLOAD_ERROR: $downloadError');
      return;
    }

    if (asset.sha256 case final expected?) {
      final actual = await sha256.bind(file.openRead()).first;
      if ('$actual' != expected.toLowerCase()) {
        yield const UpdateInstallFailed('CHECKSUM_ERROR');
        return;
      }
    }

    if (isRpm) {
      yield const UpdateInstalling();
      await _rpm.install(file);
      await dir.delete(recursive: true);
      await _rpm.restart();
      return;
    }
    await _replace(file, appImage);
    yield const UpdateInstallFailed('INSTALLATION_ERROR: unsupported OS');
  }

  /// Starts the replacement and quits; returns only when this OS has none.
  Future<void> _replace(File file, String? appImage) async {
    if (Platform.isWindows) {
      await Process.start(file.path, [
        '/SILENT',
        '/SUPPRESSMSGBOXES',
        '/NORESTART',
      ], mode: ProcessStartMode.detached);
      exit(0);
    }
    final String script;
    final Map<String, String> env;
    if (Platform.isMacOS) {
      // …/Yoru.app/Contents/MacOS/Yoru
      final app = File(Platform.resolvedExecutable).parent.parent.parent.path;
      // The new bundle keeps its own name next to the old one's place, so
      // an install from before the rename (BacaKomik.app) becomes Yoru.app.
      script = r'''
while kill -0 "$PID" 2>/dev/null; do sleep 0.3; done
dir=$(mktemp -d)
ditto -x -k "$FILE" "$dir" || exit 1
new=$(find "$dir" -maxdepth 1 -name '*.app' | head -n 1)
[ -n "$new" ] || exit 1
dest="$(dirname "$APP")/$(basename "$new")"
rm -rf "$APP" "$dest" && mv "$new" "$dest"
xattr -dr com.apple.quarantine "$dest" 2>/dev/null
rm -rf "$dir" "$FILE"
open "$dest"
''';
      env = {'APP': app};
    } else if (Platform.isLinux) {
      script = r'''
while kill -0 "$PID" 2>/dev/null; do sleep 0.3; done
mv -f "$FILE" "$APP" && chmod +x "$APP"
nohup "$APP" >/dev/null 2>&1 &
''';
      env = {'APP': appImage!};
    } else {
      return;
    }
    await Process.start(
      '/bin/sh',
      ['-c', script],
      environment: {...env, 'FILE': file.path, 'PID': '$pid'},
      mode: ProcessStartMode.detached,
    );
    exit(0);
  }
}
