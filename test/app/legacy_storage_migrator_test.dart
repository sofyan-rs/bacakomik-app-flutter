import 'package:bacakomik_app/app/legacy_storage_migrator.dart';
import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:bacakomik_app/core/storage/hive_boxes.dart';
import 'package:bacakomik_app/features/bookmark/data/datasources/bookmark_local_data_source.dart';
import 'package:bacakomik_app/features/history/data/datasources/history_local_data_source.dart';
import 'package:bacakomik_app/features/settings/data/datasources/settings_local_data_source.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

import '../fixtures/legacy_storage_fixtures.dart';
import '../helpers/hive.dart';

void main() {
  late Future<void> Function() tearDownHive;
  late Box<String> meta;
  late BookmarkLocalDataSource bookmarks;
  late HistoryLocalDataSource history;
  late SettingsLocalDataSource settings;

  setUp(() async {
    tearDownHive = await setUpTempHive();
    meta = await Hive.openBox<String>(HiveBoxes.meta);
    bookmarks = BookmarkLocalDataSourceImpl(
      await Hive.openBox<String>(HiveBoxes.bookmarks),
    );
    history = HistoryLocalDataSourceImpl(
      await Hive.openBox<String>(HiveBoxes.history),
    );
    settings = SettingsLocalDataSourceImpl(
      await Hive.openBox<String>(HiveBoxes.settings),
    );
  });

  tearDown(() => tearDownHive());

  LegacyStorageMigrator migrator() =>
      LegacyStorageMigrator(Hive, meta, bookmarks, history, settings);

  /// Writes the box the way hydrated_bloc did and closes it.
  Future<void> writeLegacyBox(Map<String, dynamic> values) async {
    final box = await Hive.openBox<dynamic>(HiveBoxes.legacyHydrated);
    await box.putAll(values);
    await box.close();
  }

  test('copies bookmarks, history and settings from hydrated_box', () async {
    await writeLegacyBox({
      LegacyStorageMigrator.bookmarkToken: legacyBookmarkStorage,
      LegacyStorageMigrator.historyToken: legacyHistoryStorage,
      LegacyStorageMigrator.settingsToken: legacySettingsStorage,
    });

    await migrator().migrate();

    final bookmark = bookmarks.getAll().single;
    expect(bookmark.slug, 'solo-leveling');
    expect(bookmark.comicDetails.chapters, hasLength(2));
    expect(bookmark.updatedDate.millisecondsSinceEpoch, 1700000000000);

    expect(
      history.getAll().map((h) => h.slug),
      unorderedEquals(['solo-leveling/1', 'solo-leveling/2']),
    );
    expect(settings.get()!.darkMode, AppText.dark);
    expect(migrator().isDone, isTrue);
  });

  test('accepts entries stored as maps instead of strings', () async {
    await writeLegacyBox({
      LegacyStorageMigrator.bookmarkToken: {
        'bookmarks_comic': [
          LegacyStorageMigrator.asJsonMap(legacyBookmarkEntry),
        ],
      },
      LegacyStorageMigrator.settingsToken: {
        'value': {'darkMode': AppText.light},
      },
    });

    await migrator().migrate();

    expect(bookmarks.getAll().single.slug, 'solo-leveling');
    expect(settings.get()!.darkMode, AppText.light);
  });

  test('skips unreadable entries and keeps the rest', () async {
    await writeLegacyBox({
      LegacyStorageMigrator.bookmarkToken: {
        'bookmarks_comic': ['not json', legacyBookmarkEntry],
      },
    });

    await migrator().migrate();

    expect(bookmarks.getAll().single.slug, 'solo-leveling');
  });

  test('runs only once', () async {
    await writeLegacyBox({
      LegacyStorageMigrator.bookmarkToken: legacyBookmarkStorage,
    });
    await migrator().migrate();
    await bookmarks.deleteAll(['solo-leveling']);

    await migrator().migrate();

    expect(bookmarks.getAll(), isEmpty);
  });

  test('fresh install: nothing to copy, marked done', () async {
    await migrator().migrate();

    expect(bookmarks.getAll(), isEmpty);
    expect(migrator().isDone, isTrue);
  });
}
