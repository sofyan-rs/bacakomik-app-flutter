import 'package:bacakomik_app/features/settings/domain/entities/app_settings.dart';
import 'package:json_annotation/json_annotation.dart';

part 'settings_model.g.dart';

/// Stored settings. Missing or unknown values fall back to the defaults.
@JsonSerializable()
class SettingsModel {
  const SettingsModel({
    this.themeMode = AppThemeMode.system,
    this.readingDirection = ReadingDirection.vertical,
    this.pageFit = PageFit.width,
    this.keepScreenOn = true,
    this.pageGap = false,
  });

  factory SettingsModel.fromEntity(AppSettings e) => SettingsModel(
    themeMode: e.themeMode,
    readingDirection: e.readingDirection,
    pageFit: e.pageFit,
    keepScreenOn: e.keepScreenOn,
    pageGap: e.pageGap,
  );

  factory SettingsModel.fromJson(Map<String, dynamic> json) =>
      _$SettingsModelFromJson(json);

  @JsonKey(unknownEnumValue: AppThemeMode.system)
  final AppThemeMode themeMode;

  @JsonKey(unknownEnumValue: ReadingDirection.vertical)
  final ReadingDirection readingDirection;

  @JsonKey(unknownEnumValue: PageFit.width)
  final PageFit pageFit;

  final bool keepScreenOn;
  final bool pageGap;

  Map<String, dynamic> toJson() => _$SettingsModelToJson(this);

  AppSettings toEntity() => AppSettings(
    themeMode: themeMode,
    readingDirection: readingDirection,
    pageFit: pageFit,
    keepScreenOn: keepScreenOn,
    pageGap: pageGap,
  );
}
