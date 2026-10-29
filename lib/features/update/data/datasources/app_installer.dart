import 'dart:async';
import 'dart:io';

import 'package:bacakomik_app/core/di/register_module.dart';
import 'package:bacakomik_app/features/update/domain/entities/app_release.dart';
import 'package:bacakomik_app/features/update/domain/entities/update_progress.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:ota_update/ota_update.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

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
  AppInstaller installer(@Named(filesDio) Dio dio) =>
      Platform.isAndroid ? OtaAppInstaller() : DesktopAppInstaller(dio);
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

/// Desktop: downloads the release asset, then quits while a detached script
/// puts it in place of the running app and opens it again.
///
/// macOS takes `…-macos.zip` (the `.app`, replaced where it runs from),
/// Windows `…-windows-setup.exe` (run silently; it relaunches the app),
/// Linux `…-linux-x86_64.AppImage` (replaces the AppImage that runs).
class DesktopAppInstaller implements AppInstaller {
  DesktopAppInstaller(this._dio);

  final Dio _dio;

  @override
  Future<String> installedVersion() => _installedVersion();

  @override
  Future<List<String>> assetSuffixes() async => [
    if (Platform.isMacOS) 'macos.zip',
    if (Platform.isWindows) 'windows-setup.exe',
    if (Platform.isLinux) 'linux-x86_64.AppImage',
  ];

  @override
  Stream<UpdateProgress> install(ReleaseAsset asset) async* {
    // Linux replaces the AppImage it runs from; a build run any other way
    // cannot update itself.
    final appImage = Platform.environment['APPIMAGE'];
    if (Platform.isLinux && appImage == null) {
      yield const UpdateInstallFailed('Not running from an AppImage');
      return;
    }

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}${Platform.pathSeparator}${asset.name}');
    final progress = StreamController<int>();
    final download = _dio
        .download(
          asset.url,
          file.path,
          onReceiveProgress: (received, total) {
            if (total > 0) progress.add(received * 100 ~/ total);
          },
        )
        .whenComplete(progress.close);
    yield const UpdateDownloading(0);
    await for (final percent in progress.stream) {
      yield UpdateDownloading(percent);
    }
    try {
      await download;
    } on DioException catch (e) {
      yield UpdateInstallFailed('DOWNLOAD_ERROR: ${e.message}');
      return;
    }

    if (asset.sha256 case final expected?) {
      final actual = await sha256.bind(file.openRead()).first;
      if ('$actual' != expected.toLowerCase()) {
        yield const UpdateInstallFailed('CHECKSUM_ERROR');
        return;
      }
    }

    try {
      await _replace(file, appImage);
    } on ProcessException catch (e) {
      yield UpdateInstallFailed('INSTALLATION_ERROR: ${e.message}');
      return;
    }
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
      // …/BacaKomik.app/Contents/MacOS/BacaKomik
      final app = File(Platform.resolvedExecutable).parent.parent.parent.path;
      script = r'''
while kill -0 "$PID" 2>/dev/null; do sleep 0.3; done
dir=$(mktemp -d)
ditto -x -k "$FILE" "$dir" || exit 1
new=$(find "$dir" -maxdepth 1 -name '*.app' | head -n 1)
[ -n "$new" ] || exit 1
rm -rf "$APP" && mv "$new" "$APP"
xattr -dr com.apple.quarantine "$APP" 2>/dev/null
rm -rf "$dir" "$FILE"
open "$APP"
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
