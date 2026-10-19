import 'dart:convert';

import 'package:bacakomik_app/core/storage/hive_boxes.dart';
import 'package:bacakomik_app/features/bookmark/data/datasources/bookmark_local_data_source.dart';
import 'package:bacakomik_app/features/bookmark/data/models/bookmark_model.dart';
import 'package:bacakomik_app/features/history/data/datasources/history_local_data_source.dart';
import 'package:bacakomik_app/features/history/data/models/read_history_model.dart';
import 'package:bacakomik_app/features/settings/data/datasources/settings_local_data_source.dart';
import 'package:bacakomik_app/features/settings/data/models/settings_model.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive.dart';
import 'package:injectable/injectable.dart';

/// Copies bookmarks, history and settings that earlier app versions kept in
/// hydrated_bloc's `hydrated_box` into the new Hive boxes. Runs once; the old
/// box is left on disk untouched.
@lazySingleton
class LegacyStorageMigrator {
  LegacyStorageMigrator(
    this._hive,
    @Named(HiveBoxes.meta) this._meta,
    this._bookmarks,
    this._history,
    this._settings,
  );

  final HiveInterface _hive;
  final Box<String> _meta;
  final BookmarkLocalDataSource _bookmarks;
  final HistoryLocalDataSource _history;
  final SettingsLocalDataSource _settings;

  static const doneKey = 'hydrated_migrated_v1';

  // hydrated_bloc storage tokens (cubit class names, BookmarkCubit kept its
  // old FavoriteCubit prefix) and the JSON keys each cubit wrote.
  static const bookmarkToken = 'FavoriteCubit';
  static const historyToken = 'HistoryCubit';
  static const settingsToken = 'SettingsCubit';

  bool get isDone => _meta.get(doneKey) == 'true';

  Future<void> migrate() async {
    if (isDone) return;
    try {
      if (await _hive.boxExists(HiveBoxes.legacyHydrated)) {
        final legacy = await _hive.openBox<dynamic>(HiveBoxes.legacyHydrated);
        try {
          await _copy(legacy);
        } finally {
          await legacy.close();
        }
      }
      await _meta.put(doneKey, 'true');
    } catch (e, s) {
      // Not marked done, so the next launch retries.
      debugPrint('Legacy storage migration failed: $e\n$s');
    }
  }

  Future<void> _copy(Box<dynamic> legacy) async {
    final bookmarks = _entries(legacy.get(bookmarkToken), 'bookmarks_comic')
        .map(BookmarkModel.fromJson)
        .toList();
    if (bookmarks.isNotEmpty) await _bookmarks.putAll(bookmarks);

    final history = _entries(legacy.get(historyToken), 'history_read')
        .map(ReadHistoryModel.fromJson)
        .toList();
    if (history.isNotEmpty) await _history.putAll(history);

    final settings = legacy.get(settingsToken);
    if (settings is Map && settings['value'] != null) {
      await _settings.put(SettingsModel.fromJson(asJsonMap(settings['value'])));
    }
  }

  /// Entries of the list stored under [listKey]. Unreadable entries are
  /// skipped so one bad record does not block the rest.
  Iterable<Map<String, dynamic>> _entries(Object? stored, String listKey) sync* {
    if (stored is! Map || stored[listKey] is! List) return;
    for (final entry in stored[listKey] as List) {
      try {
        yield asJsonMap(entry);
      } catch (e) {
        debugPrint('Skipping unreadable legacy $listKey entry: $e');
      }
    }
  }

  /// Old models stored themselves as encoded JSON strings; Hive may also
  /// hand back nested `Map<dynamic, dynamic>`. Normalise both.
  @visibleForTesting
  static Map<String, dynamic> asJsonMap(Object? value) => switch (value) {
        String() => jsonDecode(value) as Map<String, dynamic>,
        Map() => jsonDecode(jsonEncode(value)) as Map<String, dynamic>,
        _ => throw FormatException('Unexpected legacy value: $value'),
      };
}
