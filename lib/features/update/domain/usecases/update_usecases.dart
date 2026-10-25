import 'package:bacakomik_app/core/error/failures.dart';
import 'package:bacakomik_app/core/usecase/usecase.dart';
import 'package:bacakomik_app/features/update/domain/entities/app_release.dart';
import 'package:bacakomik_app/core/utils/version.dart';
import 'package:bacakomik_app/features/update/domain/entities/update_progress.dart';
import 'package:bacakomik_app/features/update/domain/repositories/update_repository.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

/// The latest release when it is newer than the installed app, else `null`.
@injectable
class CheckForUpdate implements UseCase<AppRelease?, NoParams> {
  const CheckForUpdate(this._repository);

  final UpdateRepository _repository;

  @override
  Future<Either<Failure, AppRelease?>> call(NoParams params) async {
    final installed = await _repository.installedVersion();
    final result = await _repository.latestRelease();
    return result.map(
      (release) => isNewerVersion(release.version, installed) ? release : null,
    );
  }
}

/// Downloads the APK of [AppRelease] that fits the device and installs it.
@injectable
class InstallUpdate {
  const InstallUpdate(this._repository);

  final UpdateRepository _repository;

  Stream<UpdateProgress> call(AppRelease release) async* {
    final apk = release.apkFor(await _repository.deviceAbi());
    if (apk == null) {
      yield const UpdateInstallFailed('No APK for this device');
      return;
    }
    yield* _repository.install(apk);
  }
}
