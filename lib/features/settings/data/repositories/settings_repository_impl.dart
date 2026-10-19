import 'package:bacakomik_app/core/error/failures.dart';
import 'package:bacakomik_app/core/storage/local_call.dart';
import 'package:bacakomik_app/features/settings/data/datasources/settings_local_data_source.dart';
import 'package:bacakomik_app/features/settings/data/models/settings_model.dart';
import 'package:bacakomik_app/features/settings/domain/entities/app_settings.dart';
import 'package:bacakomik_app/features/settings/domain/repositories/settings_repository.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: SettingsRepository)
class SettingsRepositoryImpl implements SettingsRepository {
  const SettingsRepositoryImpl(this._local);

  final SettingsLocalDataSource _local;

  @override
  Future<Either<Failure, AppSettings>> getSettings() =>
      runLocal(() => _local.get()?.toEntity() ?? const AppSettings());

  @override
  Future<Either<Failure, Unit>> saveSettings(AppSettings settings) =>
      runLocal(() async {
        await _local.put(SettingsModel.fromEntity(settings));
        return unit;
      });
}
