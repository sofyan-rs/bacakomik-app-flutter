import 'package:bacakomik_app/core/usecase/usecase.dart';
import 'package:bacakomik_app/features/settings/domain/entities/app_settings.dart';
import 'package:bacakomik_app/features/settings/domain/usecases/settings_usecases.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

@injectable
class SettingsCubit extends Cubit<AppSettings> {
  SettingsCubit(this._getSettings, this._saveSettings)
    : super(const AppSettings());

  final GetSettings _getSettings;
  final SaveSettings _saveSettings;

  Future<void> load() async {
    final result = await _getSettings(const NoParams());
    result.fold((f) => debugPrint('SettingsCubit: $f'), emit);
  }

  Future<void> changeDarkMode(String darkMode) =>
      update((s) => s.copyWith(darkMode: darkMode));

  /// Applies [change] and saves the result (reader settings sheet).
  Future<void> update(AppSettings Function(AppSettings) change) async {
    final settings = change(state);
    emit(settings);
    final result = await _saveSettings(settings);
    result.fold((f) => debugPrint('SettingsCubit: $f'), (_) {});
  }
}
