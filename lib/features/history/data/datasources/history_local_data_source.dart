import 'package:bacakomik_app/core/storage/hive_boxes.dart';
import 'package:bacakomik_app/core/storage/json_box.dart';
import 'package:bacakomik_app/features/history/data/models/read_history_model.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive.dart';
import 'package:injectable/injectable.dart';

/// Read chapters in one box, the details of their comics in another (one
/// record per comic).
///
/// Entries are keyed by chapter slug, `<comicSlug>/<number>` (see
/// `ApiFormat.chapterSlug`), so a comic's entries are found by key without
/// decoding them.
abstract interface class HistoryLocalDataSource {
  List<ReadHistoryModel> getEntries();

  ReadHistoryModel? getEntry(String slug);

  /// Every entry key (chapter slug), without decoding.
  List<String> entryKeys();

  /// Keys of the entries of [comicSlugs], by key.
  List<String> entryKeysOf(Set<String> comicSlugs);

  /// Those of [comicSlugs] that still have an entry, by key.
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

  /// The comic part of a chapter slug; null without a `/`.
  static String? _comicOf(String chapterSlug) {
    final i = chapterSlug.lastIndexOf('/');
    return i > 0 ? chapterSlug.substring(0, i) : null;
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
