import 'package:bacakomik_app/features/settings/data/models/settings_model.dart';
import 'package:bacakomik_app/features/settings/domain/entities/app_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('missing fields fall back to the defaults', () {
    expect(SettingsModel.fromJson({}).toEntity(), const AppSettings());
  });

  test('settings round-trip', () {
    const settings = AppSettings(
      themeMode: AppThemeMode.dark,
      readingDirection: ReadingDirection.rightToLeft,
      pageFit: PageFit.height,
      keepScreenOn: false,
      pageGap: true,
      autoScrollSpeed: 7,
      bookmarkSort: BookmarkSort.lastRead,
      bookmarkSortDirection: SortDirection.ascending,
    );
    final json = SettingsModel.fromEntity(settings).toJson();

    expect(json['themeMode'], 'dark');
    expect(SettingsModel.fromJson(json).toEntity(), settings);
  });

  test('auto-scroll speed is clamped to the levels', () {
    expect(
      SettingsModel.fromJson({'autoScrollSpeed': 99})
          .toEntity()
          .autoScrollSpeed,
      autoScrollMax,
    );
    expect(
      SettingsModel.fromJson({'autoScrollSpeed': 0}).toEntity().autoScrollSpeed,
      autoScrollMin,
    );
  });

  test('unknown enum values fall back', () {
    final settings = SettingsModel.fromJson({
      'themeMode': 'sepia',
      'readingDirection': 'diagonal',
      'pageFit': 'stretch',
      'bookmarkSort': 'rating',
      'bookmarkSortDirection': 'sideways',
    }).toEntity();

    expect(settings.themeMode, AppThemeMode.system);
    expect(settings.readingDirection, ReadingDirection.vertical);
    expect(settings.pageFit, PageFit.width);
    expect(settings.bookmarkSort, BookmarkSort.updated);
    expect(settings.bookmarkSortDirection, SortDirection.descending);
  });
}
