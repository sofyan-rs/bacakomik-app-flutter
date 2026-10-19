import 'package:bacakomik_app/core/error/failures.dart';
import 'package:bacakomik_app/features/update/domain/entities/app_release.dart';
import 'package:bacakomik_app/features/update/domain/entities/update_progress.dart';
import 'package:fpdart/fpdart.dart';

abstract interface class UpdateRepository {
  /// Newest published release, excluding drafts and pre-releases.
  Future<Either<Failure, AppRelease>> latestRelease();

  /// Version name of the installed app, e.g. `1.0.0`.
  Future<String> installedVersion();

  /// Preferred ABI of the device, e.g. `arm64-v8a`.
  Future<String?> deviceAbi();

  /// Downloads [apk] and opens Android's installer.
  Stream<UpdateProgress> install(ReleaseApk apk);
}
