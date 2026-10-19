import 'package:bacakomik_app/core/error/failures.dart';
import 'package:bacakomik_app/core/network/network_info.dart';
import 'package:bacakomik_app/core/network/remote_call.dart';
import 'package:bacakomik_app/features/update/data/datasources/apk_installer.dart';
import 'package:bacakomik_app/features/update/data/datasources/update_remote_data_source.dart';
import 'package:bacakomik_app/features/update/domain/entities/app_release.dart';
import 'package:bacakomik_app/features/update/domain/entities/update_progress.dart';
import 'package:bacakomik_app/features/update/domain/repositories/update_repository.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: UpdateRepository)
class UpdateRepositoryImpl implements UpdateRepository {
  const UpdateRepositoryImpl(this._remote, this._installer, this._networkInfo);

  final UpdateRemoteDataSource _remote;
  final ApkInstaller _installer;
  final NetworkInfo _networkInfo;

  @override
  Future<Either<Failure, AppRelease>> latestRelease() => runRemote(
    _networkInfo,
    () async => (await _remote.latestRelease()).toEntity(),
  );

  @override
  Future<String> installedVersion() => _installer.installedVersion();

  @override
  Future<String?> deviceAbi() => _installer.deviceAbi();

  @override
  Stream<UpdateProgress> install(ReleaseApk apk) => _installer.install(apk);
}
