import 'package:bacakomik_app/core/error/failures.dart';
import 'package:bacakomik_app/core/usecase/usecase.dart';
import 'package:bacakomik_app/features/settings/domain/entities/app_settings.dart';
import 'package:bacakomik_app/features/settings/domain/repositories/settings_repository.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

@injectable
class GetSettings implements UseCase<AppSettings, NoParams> {
  const GetSettings(this._repository);

  final SettingsRepository _repository;

  @override
  Future<Either<Failure, AppSettings>> call(NoParams params) =>
      _repository.getSettings();
}

@injectable
class SaveSettings implements UseCase<Unit, AppSettings> {
  const SaveSettings(this._repository);

  final SettingsRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(AppSettings settings) =>
      _repository.saveSettings(settings);
}
