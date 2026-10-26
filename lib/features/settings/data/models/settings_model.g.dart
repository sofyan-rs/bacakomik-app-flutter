// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SettingsModel _$SettingsModelFromJson(Map<String, dynamic> json) =>
    SettingsModel(
      themeMode:
          $enumDecodeNullable(
            _$AppThemeModeEnumMap,
            json['themeMode'],
            unknownValue: AppThemeMode.system,
          ) ??
          AppThemeMode.system,
      readingDirection:
          $enumDecodeNullable(
            _$ReadingDirectionEnumMap,
            json['readingDirection'],
            unknownValue: ReadingDirection.vertical,
          ) ??
          ReadingDirection.vertical,
      pageFit:
          $enumDecodeNullable(
            _$PageFitEnumMap,
            json['pageFit'],
            unknownValue: PageFit.width,
          ) ??
          PageFit.width,
      keepScreenOn: json['keepScreenOn'] as bool? ?? true,
      pageGap: json['pageGap'] as bool? ?? false,
      progressBar: json['progressBar'] as bool? ?? true,
      autoScrollSpeed: (json['autoScrollSpeed'] as num?)?.toInt() ?? 3,
      incognito: json['incognito'] as bool? ?? false,
      bookmarkGrouping:
          $enumDecodeNullable(
            _$BookmarkGroupingEnumMap,
            json['bookmarkGrouping'],
            unknownValue: BookmarkGrouping.status,
          ) ??
          BookmarkGrouping.status,
      bookmarkSort:
          $enumDecodeNullable(
            _$BookmarkSortEnumMap,
            json['bookmarkSort'],
            unknownValue: BookmarkSort.updated,
          ) ??
          BookmarkSort.updated,
      bookmarkSortDirection:
          $enumDecodeNullable(
            _$SortDirectionEnumMap,
            json['bookmarkSortDirection'],
            unknownValue: SortDirection.descending,
          ) ??
          SortDirection.descending,
    );

Map<String, dynamic> _$SettingsModelToJson(SettingsModel instance) =>
    <String, dynamic>{
      'themeMode': _$AppThemeModeEnumMap[instance.themeMode]!,
      'readingDirection': _$ReadingDirectionEnumMap[instance.readingDirection]!,
      'pageFit': _$PageFitEnumMap[instance.pageFit]!,
      'keepScreenOn': instance.keepScreenOn,
      'pageGap': instance.pageGap,
      'progressBar': instance.progressBar,
      'autoScrollSpeed': instance.autoScrollSpeed,
      'incognito': instance.incognito,
      'bookmarkGrouping': _$BookmarkGroupingEnumMap[instance.bookmarkGrouping]!,
      'bookmarkSort': _$BookmarkSortEnumMap[instance.bookmarkSort]!,
      'bookmarkSortDirection':
          _$SortDirectionEnumMap[instance.bookmarkSortDirection]!,
    };

const _$AppThemeModeEnumMap = {
  AppThemeMode.system: 'system',
  AppThemeMode.light: 'light',
  AppThemeMode.dark: 'dark',
};

const _$ReadingDirectionEnumMap = {
  ReadingDirection.vertical: 'vertical',
  ReadingDirection.rightToLeft: 'rightToLeft',
  ReadingDirection.leftToRight: 'leftToRight',
};

const _$PageFitEnumMap = {PageFit.width: 'width', PageFit.height: 'height'};

const _$BookmarkGroupingEnumMap = {
  BookmarkGrouping.status: 'status',
  BookmarkGrouping.source: 'source',
  BookmarkGrouping.category: 'category',
};

const _$BookmarkSortEnumMap = {
  BookmarkSort.updated: 'updated',
  BookmarkSort.title: 'title',
  BookmarkSort.chapters: 'chapters',
  BookmarkSort.latestChapter: 'latestChapter',
  BookmarkSort.added: 'added',
  BookmarkSort.lastRead: 'lastRead',
  BookmarkSort.unread: 'unread',
};

const _$SortDirectionEnumMap = {
  SortDirection.ascending: 'ascending',
  SortDirection.descending: 'descending',
};
