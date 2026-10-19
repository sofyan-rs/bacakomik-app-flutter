import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

import 'package:bacakomik_app/core/models/settings_model.dart';

class SettingsCubit extends HydratedCubit<SettingsModel> {
  SettingsCubit() : super(SettingsModel(darkMode: AppText.system));

  void changeDarkMode(String darkMode) {
    emit(state.copyWith(darkMode: darkMode));
  }

  // Older builds stored the model under 'value' as an encoded JSON string.
  @override
  SettingsModel? fromJson(Map<String, dynamic> json) {
    final value = json['value'];
    if (value is String) return SettingsModel.fromJson(value);
    if (value is Map) {
      return SettingsModel.fromMap(Map<String, dynamic>.from(value));
    }
    return null;
  }

  @override
  Map<String, dynamic> toJson(SettingsModel state) => {'value': state.toJson()};
}
