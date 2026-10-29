import 'dart:convert';

import 'package:bacakomik_app/core/storage/hive_boxes.dart';
import 'package:bacakomik_app/core/storage/json_box.dart';
import 'package:bacakomik_app/features/history/data/models/read_history_model.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive.dart';
import 'package:injectable/injectable.dart';

/// Read chapters in one box, the details of their comics in another (one
/// record per comic).
///
/// Entries are keyed by chapter slug, `<seriesKey>/<number>` (see
/// `ApiFormat.chapterSlug`). The comic an entry belongs to is usually that
/// series, but a merged bookmark keeps chapters of other series under its
/// own key, so the comic is read from the stored JSON, without decoding the
/// rest of the entry.
abstract interface class HistoryLocalDataSource {
  List<ReadHistoryModel> getEntries();

  ReadHistoryModel? getEntry(String slug);

  /// Every entry key (chapter slug), without decoding.
  List<String> entryKeys();

  /// Keys of the entries of [comicSlugs].
  List<String> entryKeysOf(Set<String> comicSlugs);

  /// Those of [comicSlugs] that still have an entry.
  Set<String> comicsWithEntries(Set<String> comicSlugs);

  Map<String, HistoryComicModel> getComics();

  /// One comic record, decoding only it; null when absent or unreadable.
  HistoryComicModel? getComic(String comicSlug);

  /// The stored JSON of a comic record; the same string until the record
  /// is written again.
  String? comicJson(String comicSlug);

  Future<void> putEntries(List<ReadHistoryModel> entries);

  /// Writes the comic records whose stored JSON differs.
  Future<void> putComics(List<HistoryComicModel> comics);

  Future<void> deleteEntries(List<String> slugs);

  Future<void> deleteComics(List<String> comicSlugs);

  Future<void> clear();

  RawJsonStore get rawEntries;

  RawJsonStore get rawComics;
}

@LazySingleton(as: HistoryLocalDataSource)
class HistoryLocalDataSourceImpl implements HistoryLocalDataSource {
  HistoryLocalDataSourceImpl(
    @Named(HiveBoxes.historyEntries) Box<String> entries,
    @Named(HiveBoxes.historyComics) Box<String> comics,
  ) : _entries = JsonBox(
        entries,
        fromJson: ReadHistoryModel.fromJson,
        toJson: (h) => h.toJson(),
        keyOf: (h) => h.slug,
      ),
      _comics = JsonBox(
        comics,
        fromJson: HistoryComicModel.fromJson,
        toJson: (c) => c.toJson(),
        keyOf: (c) => c.slug,
      );

  final JsonBox<ReadHistoryModel> _entries;
  final JsonBox<HistoryComicModel> _comics;

  static final _comicSlugField = RegExp(r'"comicSlug":("(?:[^"\\]|\\.)*")');

  /// The `comicSlug` of the entry stored under [key], read from its JSON;
  /// null when absent or unreadable.
  String? _comicOf(String key) {
    final raw = _entries.raw(key);
    if (raw == null) return null;
    final match = _comicSlugField.firstMatch(raw);
    if (match == null) return null;
    final value = match.group(1)!;
    // Escapes are rare in keys; only then is the string decoded.
    return value.contains('\\')
        ? jsonDecode(value) as String
        : value.substring(1, value.length - 1);
  }

  @override
  List<ReadHistoryModel> getEntries() => _entries.values();

  @override
  ReadHistoryModel? getEntry(String slug) => _entries.get(slug);

  @override
  List<String> entryKeys() => _entries.keys.toList();

  @override
  List<String> entryKeysOf(Set<String> comicSlugs) => [
    for (final key in _entries.keys)
      if (comicSlugs.contains(_comicOf(key))) key,
  ];

  @override
  Set<String> comicsWithEntries(Set<String> comicSlugs) => {
    for (final key in _entries.keys)
      if (_comicOf(key) case final comic? when comicSlugs.contains(comic))
        comic,
  };

  @override
  Map<String, HistoryComicModel> getComics() => {
    for (final comic in _comics.values()) comic.slug: comic,
  };

  @override
  HistoryComicModel? getComic(String comicSlug) {
    try {
      return _comics.get(comicSlug);
    } catch (e) {
      debugPrint('Skipping unreadable history comic $comicSlug: $e');
      return null;
    }
  }

  @override
  String? comicJson(String comicSlug) => _comics.raw(comicSlug);

  @override
  Future<void> putEntries(List<ReadHistoryModel> entries) =>
      _entries.putAll(entries);

  @override
  Future<void> putComics(List<HistoryComicModel> comics) =>
      _comics.putAllChanged(comics);

  @override
  Future<void> deleteEntries(List<String> slugs) => _entries.deleteAll(slugs);

  @override
  Future<void> deleteComics(List<String> comicSlugs) =>
      _comics.deleteAll(comicSlugs);

  @override
  Future<void> clear() async {
    await _entries.clear();
    await _comics.clear();
  }

  @override
  RawJsonStore get rawEntries => _entries;

  @override
  RawJsonStore get rawComics => _comics;
}
