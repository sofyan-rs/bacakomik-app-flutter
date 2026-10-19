import 'dart:convert';

import 'package:bacakomik_app/core/bloc/bookmark_cubit/bookmark_cubit.dart';
import 'package:bacakomik_app/core/bloc/history_cubit/history_cubit.dart';
import 'package:bacakomik_app/core/bloc/settings_cubit/settings_cubit.dart';
import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:bacakomik_app/core/models/bookmark_model.dart';
import 'package:bacakomik_app/core/models/history_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fixtures/legacy_storage_fixtures.dart';
import '../helpers/hydrated_storage.dart';

void main() {
  setUp(mockHydratedStorage);

  group('BookmarkCubit storage', () {
    test('keeps legacy storage prefix', () {
      expect(BookmarkCubit().storagePrefix, 'FavoriteCubit');
    });

    test('reads legacy bookmarks_comic payload', () {
      final bookmarks = BookmarkCubit().fromJson(legacyBookmarkStorage)!;

      expect(bookmarks.single.slug, 'solo-leveling');
      expect(bookmarks.single.comicDetails.chapters, hasLength(2));
      expect(
        bookmarks.single.updatedDate.millisecondsSinceEpoch,
        1700000000000,
      );
    });

    test('writes the same shape it reads', () {
      final cubit = BookmarkCubit();
      final bookmarks = cubit.fromJson(legacyBookmarkStorage)!;

      expect(cubit.toJson(bookmarks), legacyBookmarkStorage);
    });
  });

  group('HistoryCubit storage', () {
    test('reads legacy history_read payload', () {
      final history = HistoryCubit().fromJson(legacyHistoryStorage)!;

      expect(
        history.map((h) => h.slug),
        ['solo-leveling/1', 'solo-leveling/2'],
      );
    });

    test('writes the same shape it reads', () {
      final cubit = HistoryCubit();
      final history = cubit.fromJson(legacyHistoryStorage)!;

      expect(cubit.toJson(history), legacyHistoryStorage);
    });
  });

  group('SettingsCubit storage', () {
    test('reads legacy value payload', () {
      final settings = SettingsCubit().fromJson(legacySettingsStorage)!;

      expect(settings.darkMode, AppText.dark);
    });

    test('writes the same shape it reads', () {
      final cubit = SettingsCubit();

      expect(
        cubit.toJson(cubit.fromJson(legacySettingsStorage)!),
        legacySettingsStorage,
      );
    });
  });

  group('backup file', () {
    // Mirrors the parsing in core/utils/backup_restore_data.dart.
    List<BookmarkModel> parseBookmarks(Map<String, dynamic> json) =>
        List<BookmarkModel>.from(
          (json['bookmarks'] ?? json['favorites'])
              .map((x) => BookmarkModel.fromJson(x)),
        );

    test('parses bookmarks and history', () {
      final json = jsonDecode(legacyBackupFile()) as Map<String, dynamic>;

      expect(parseBookmarks(json).single.slug, 'solo-leveling');
      expect(
        List<HistoryModel>.from(
          json['history'].map((x) => HistoryModel.fromJson(x)),
        ),
        hasLength(2),
      );
    });

    test('accepts legacy favorites key', () {
      final json = jsonDecode(legacyBackupFile(bookmarkKey: 'favorites'))
          as Map<String, dynamic>;

      expect(parseBookmarks(json).single.slug, 'solo-leveling');
    });

    test('encoding current models reproduces the file shape', () {
      final bookmarks = BookmarkCubit().fromJson(legacyBookmarkStorage)!;
      final history = HistoryCubit().fromJson(legacyHistoryStorage)!;

      expect(
        jsonDecode(jsonEncode({'bookmarks': bookmarks, 'history': history})),
        jsonDecode(legacyBackupFile()),
      );
    });
  });
}
