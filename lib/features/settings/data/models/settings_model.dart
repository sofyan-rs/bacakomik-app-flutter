import 'package:bacakomik_app/features/settings/domain/entities/app_settings.dart';
import 'package:json_annotation/json_annotation.dart';

part 'settings_model.g.dart';

/// Stored settings. Same JSON shape as earlier app versions.
@JsonSerializable()
class SettingsModel {
  const SettingsModel({required this.darkMode});

  factory SettingsModel.fromEntity(AppSettings e) =>
      SettingsModel(darkMode: e.darkMode);

  factory SettingsModel.fromJson(Map<String, dynamic> json) =>
      _$SettingsModelFromJson(json);

  final String darkMode;

  Map<String, dynamic> toJson() => _$SettingsModelToJson(this);

  AppSettings toEntity() => AppSettings(darkMode: darkMode);
}
