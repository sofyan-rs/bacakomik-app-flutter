import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

import 'package:bacakomik_app/core/models/settings_model.dart';

class SettingsCubit extends HydratedCubit<SettingsModel> {
  SettingsCubit()
      : super(
          SettingsModel(
            darkMode: AppText.system,
          ),
        );

  void changeDarkMode(String darkMode) {
    emit(state.copyWith(darkMode: darkMode));
  }

  @override
  SettingsModel fromJson(Map<String, dynamic> json) =>
      json['settings'] as SettingsModel;

  @override
  Map<String, SettingsModel> toJson(SettingsModel state) => {'value': state};
}
