import 'package:yoru/core/error/failures.dart';
import 'package:yoru/features/settings/domain/entities/app_settings.dart';
import 'package:fpdart/fpdart.dart';

abstract interface class SettingsRepository {
  /// Stored settings, or defaults when nothing is stored yet.
  Future<Either<Failure, AppSettings>> getSettings();

  Future<Either<Failure, Unit>> saveSettings(AppSettings settings);
}
