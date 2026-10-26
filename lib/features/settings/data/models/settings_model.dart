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
    this.progressBar = true,
    this.autoScrollSpeed = 3,
    this.incognito = false,
    this.bookmarkGrouping = BookmarkGrouping.status,
    this.bookmarkSort = BookmarkSort.updated,
    this.bookmarkSortDirection = SortDirection.descending,
  });

  factory SettingsModel.fromEntity(AppSettings e) => SettingsModel(
    themeMode: e.themeMode,
    readingDirection: e.readingDirection,
    pageFit: e.pageFit,
    keepScreenOn: e.keepScreenOn,
    pageGap: e.pageGap,
    progressBar: e.progressBar,
    autoScrollSpeed: e.autoScrollSpeed,
    incognito: e.incognito,
    bookmarkGrouping: e.bookmarkGrouping,
    bookmarkSort: e.bookmarkSort,
    bookmarkSortDirection: e.bookmarkSortDirection,
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
  final bool progressBar;
  final int autoScrollSpeed;
  final bool incognito;

  @JsonKey(unknownEnumValue: BookmarkGrouping.status)
  final BookmarkGrouping bookmarkGrouping;

  @JsonKey(unknownEnumValue: BookmarkSort.updated)
  final BookmarkSort bookmarkSort;

  @JsonKey(unknownEnumValue: SortDirection.descending)
  final SortDirection bookmarkSortDirection;

  Map<String, dynamic> toJson() => _$SettingsModelToJson(this);

  AppSettings toEntity() => AppSettings(
    themeMode: themeMode,
    readingDirection: readingDirection,
    pageFit: pageFit,
    keepScreenOn: keepScreenOn,
    pageGap: pageGap,
    progressBar: progressBar,
    autoScrollSpeed: autoScrollSpeed.clamp(autoScrollMin, autoScrollMax),
    incognito: incognito,
    bookmarkGrouping: bookmarkGrouping,
    bookmarkSort: bookmarkSort,
    bookmarkSortDirection: bookmarkSortDirection,
  );
}
