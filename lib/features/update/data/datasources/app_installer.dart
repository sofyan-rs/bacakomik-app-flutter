import 'package:bacakomik_app/features/update/domain/entities/app_release.dart';
import 'package:bacakomik_app/features/update/domain/entities/update_progress.dart';
import 'package:injectable/injectable.dart';
import 'package:ota_update/ota_update.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// The installed app and Android's package installer, via `ota_update`.
abstract interface class ApkInstaller {
  Future<String> installedVersion();

  Future<String?> deviceAbi();

  Stream<UpdateProgress> install(ReleaseApk apk);
}

@LazySingleton(as: ApkInstaller)
class OtaApkInstaller implements ApkInstaller {
  @override
  Future<String> installedVersion() async =>
      (await PackageInfo.fromPlatform()).version;

  @override
  Future<String?> deviceAbi() => OtaUpdate().getAbi();

  @override
  Stream<UpdateProgress> install(ReleaseApk apk) async* {
    // A new OtaUpdate per run: each instance replays its first stream.
    final events = OtaUpdate().execute(
      apk.url,
      destinationFilename: apk.name,
      sha256checksum: apk.sha256,
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
