import 'package:bacakomik_app/features/settings/domain/entities/app_settings.dart';
import 'package:json_annotation/json_annotation.dart';

part 'settings_model.g.dart';

/// Stored settings. Same JSON shape as earlier app versions; the reader
/// fields were added later and fall back to defaults when missing, so old
/// stored settings still load.
@JsonSerializable()
class SettingsModel {
  const SettingsModel({
    required this.darkMode,
    this.readingDirection = ReadingDirection.vertical,
    this.pageFit = PageFit.width,
    this.keepScreenOn = true,
    this.pageGap = false,
  });

  factory SettingsModel.fromEntity(AppSettings e) => SettingsModel(
    darkMode: e.darkMode,
    readingDirection: e.readingDirection,
    pageFit: e.pageFit,
    keepScreenOn: e.keepScreenOn,
    pageGap: e.pageGap,
  );

  factory SettingsModel.fromJson(Map<String, dynamic> json) =>
      _$SettingsModelFromJson(json);

  final String darkMode;

  @JsonKey(unknownEnumValue: ReadingDirection.vertical)
  final ReadingDirection readingDirection;

  @JsonKey(unknownEnumValue: PageFit.width)
  final PageFit pageFit;

  final bool keepScreenOn;
  final bool pageGap;

  Map<String, dynamic> toJson() => _$SettingsModelToJson(this);

  AppSettings toEntity() => AppSettings(
    darkMode: darkMode,
    readingDirection: readingDirection,
    pageFit: pageFit,
    keepScreenOn: keepScreenOn,
    pageGap: pageGap,
  );
}
