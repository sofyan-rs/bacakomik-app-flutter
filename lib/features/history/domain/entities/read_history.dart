import 'package:bacakomik_app/core/domain/entities/comic_details.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'read_history.freezed.dart';

/// One opened chapter, read to the end or stopped at a page.
@freezed
abstract class ReadHistory with _$ReadHistory {
  const ReadHistory._();

  const factory ReadHistory({
    /// Chapter slug (`seriesSlug/number`), unique per entry.
    required String slug,
    required String chapterNumber,
    required DateTime readDate,
    required ComicDetails comicDetails,

    /// Series slug.
    required String comicSlug,

    /// 0-based page last on screen while the chapter is unfinished. Null
    /// once the last page was reached, or when marked read from the list.
    int? page,

    /// Pages in the chapter, stored with [page].
    int? pageCount,
  }) = _ReadHistory;

  bool get isFinished => page == null;
}

/// Most recently read chapter of one comic.
@freezed
abstract class ComicLatestHistory with _$ComicLatestHistory {
  const factory ComicLatestHistory({
    required String comicSlug,
    required ComicDetails comicDetails,
    required ReadHistory latestHistory,
  }) = _ComicLatestHistory;
}

/// Read-only queries over a history list in any order. Each call scans the
/// list once; screens that query often should use [HistoryIndex].
extension ReadHistoryQueries on List<ReadHistory> {
  /// Newest [ReadHistory.readDate] first; entries read at the same time by
  /// slug, so the order does not depend on how the list was built.
  List<ReadHistory> get newestFirst => isNewestFirst ? [...this] : _sorted();

  List<ReadHistory> _sorted() => [...this]..sort(compareNewestFirst);

  /// Whether the list is already in [newestFirst] order (one pass).
  bool get isNewestFirst {
    for (var i = 1; i < length; i++) {
      if (compareNewestFirst(this[i - 1], this[i]) > 0) return false;
    }
    return true;
  }

  ReadHistory? get latest => _newest(this);

  ReadHistory? latestOf(String comicSlug) =>
      _newest(where((h) => h.comicSlug == comicSlug));

  int countOf(String comicSlug) =>
      where((h) => h.comicSlug == comicSlug).length;

  bool containsChapter(String slug) => any((h) => h.slug == slug);

  /// Newest entry per comic, newest comic first.
  List<ComicLatestHistory> get latestPerComic => HistoryIndex(this).perComic;
}

/// The order of [ReadHistoryQueries.newestFirst].
int compareNewestFirst(ReadHistory a, ReadHistory b) {
  final byDate = b.readDate.compareTo(a.readDate);
  return byDate != 0 ? byDate : a.slug.compareTo(b.slug);
}

ReadHistory? _newest(Iterable<ReadHistory> history) {
  ReadHistory? newest;
  for (final h in history) {
    if (newest == null || h.readDate.isAfter(newest.readDate)) newest = h;
  }
  return newest;
}

/// Lookups over one history list, built in a single pass so `build` methods
/// can query per row without rescanning or resorting the history. A list
/// already newest first (as `HistoryRepository.getHistory` and
/// `HistoryCubit` keep it) is used as is; any other order is sorted first.
///
/// After an edit, [applySaved], [applyRemoved], [applyRemovedComics] and
/// [applyCleared] update the index in place, touching only the comics the
/// edit changed, to what a rebuild from the edited list would hold.
class HistoryIndex {
  HistoryIndex(List<ReadHistory> history) {
    final ordered = history.isNewestFirst ? history : history._sorted();
    final perComic = <ComicLatestHistory>[];
    for (final h in ordered) {
      _chapters[h.slug] = h;
      if (h.isFinished) {
        _finished.update(h.comicSlug, (n) => n + 1, ifAbsent: () => 1);
      }
      final entries = _byComic[h.comicSlug];
      if (entries != null) {
        entries.add(h);
      } else {
        _byComic[h.comicSlug] = [h];
        perComic.add(_latestEntry(h));
      }
    }
    _perComic = perComic;
  }

  final _chapters = <String, ReadHistory>{};

  /// Entries per comic, newest first.
  final _byComic = <String, List<ReadHistory>>{};

  /// Finished entries per comic.
  final _finished = <String, int>{};

  late List<ComicLatestHistory> _perComic;

  /// Newest entry per comic, newest comic first. A new list after each
  /// change.
  List<ComicLatestHistory> get perComic => _perComic;

  ReadHistory? get latest => _perComic.firstOrNull?.latestHistory;

  ReadHistory? latestOf(String comicSlug) => _byComic[comicSlug]?.first;

  int countOf(String comicSlug) => _byComic[comicSlug]?.length ?? 0;

  /// Entries of [comicSlug] read to the end (or marked read).
  int finishedCountOf(String comicSlug) => _finished[comicSlug] ?? 0;

  bool containsChapter(String slug) => _chapters.containsKey(slug);

  /// The entry of one chapter, finished or not.
  ReadHistory? chapter(String slug) => _chapters[slug];

  bool isFinished(String slug) => _chapters[slug]?.isFinished ?? false;

  /// Comics in the history, in no particular order.
  Iterable<String> get comics => _byComic.keys;

  /// [saved] was stored: entries replace those with the same slug (the last
  /// one given wins), every entry of a saved comic takes that comic's last
  /// given details, and read dates count to the millisecond, as the history
  /// reads them back (see `HistoryCubit.withSaved`). Costs the entries of
  /// the saved comics, not the whole history.
  void applySaved(List<ReadHistory> saved) {
    if (saved.isEmpty) return;
    final details = {for (final h in saved) h.comicSlug: h.comicDetails};
    final bySlug = {for (final h in saved) h.slug: h};
    final touched = <String>{...details.keys};
    for (final h in bySlug.values) {
      if (_chapters[h.slug] case final old?) {
        touched.add(old.comicSlug);
        _remove(old);
      }
    }
    // Entries kept of a saved comic take its new details.
    for (final MapEntry(key: comic, value: d) in details.entries) {
      final entries = _byComic[comic];
      if (entries == null) continue;
      for (var i = 0; i < entries.length; i++) {
        final h = entries[i];
        if (identical(h.comicDetails, d)) continue;
        entries[i] = _chapters[h.slug] = h.copyWith(comicDetails: d);
      }
    }
    for (final h in bySlug.values) {
      _insert(
        h.copyWith(
          readDate: DateTime.fromMillisecondsSinceEpoch(
            h.readDate.millisecondsSinceEpoch,
          ),
          comicDetails: details[h.comicSlug]!,
        ),
      );
    }
    _reorder(touched);
  }

  /// The chapters [slugs] were removed.
  void applyRemoved(Iterable<String> slugs) {
    final touched = <String>{};
    for (final slug in slugs) {
      if (_chapters[slug] case final old?) {
        touched.add(old.comicSlug);
        _remove(old);
      }
    }
    _reorder(touched);
  }

  /// Every entry of [comicSlugs] was removed.
  void applyRemovedComics(Iterable<String> comicSlugs) {
    final touched = <String>{};
    for (final comic in comicSlugs) {
      final entries = _byComic.remove(comic);
      if (entries == null) continue;
      touched.add(comic);
      _finished.remove(comic);
      for (final h in entries) {
        _chapters.remove(h.slug);
      }
    }
    _reorder(touched);
  }

  /// The history was cleared.
  void applyCleared() {
    _chapters.clear();
    _byComic.clear();
    _finished.clear();
    _perComic = [];
  }

  static ComicLatestHistory _latestEntry(ReadHistory h) => ComicLatestHistory(
    comicSlug: h.comicSlug,
    comicDetails: h.comicDetails,
    latestHistory: h,
  );

  void _remove(ReadHistory h) {
    _chapters.remove(h.slug);
    final entries = _byComic[h.comicSlug];
    if (entries == null) return;
    entries.removeWhere((e) => e.slug == h.slug);
    if (entries.isEmpty) _byComic.remove(h.comicSlug);
    if (h.isFinished) {
      final left = (_finished[h.comicSlug] ?? 1) - 1;
      if (left > 0) {
        _finished[h.comicSlug] = left;
      } else {
        _finished.remove(h.comicSlug);
      }
    }
  }

  void _insert(ReadHistory h) {
    _chapters[h.slug] = h;
    if (h.isFinished) {
      _finished.update(h.comicSlug, (n) => n + 1, ifAbsent: () => 1);
    }
    final entries = _byComic.putIfAbsent(h.comicSlug, () => []);
    entries.insert(_position(entries, h, (e) => e), h);
  }

  /// Puts the [comics] whose newest entry may have changed back in order.
  void _reorder(Set<String> comics) {
    if (comics.isEmpty) return;
    final list = [
      for (final c in _perComic)
        if (!comics.contains(c.comicSlug)) c,
    ];
    for (final comic in comics) {
      final newest = _byComic[comic]?.first;
      if (newest == null) continue;
      list.insert(
        _position(list, newest, (c) => c.latestHistory),
        _latestEntry(newest),
      );
    }
    _perComic = list;
  }

  /// Where [h] goes in [list], kept in [compareNewestFirst] order of [of].
  static int _position<T>(
    List<T> list,
    ReadHistory h,
    ReadHistory Function(T) of,
  ) {
    var low = 0, high = list.length;
    while (low < high) {
      final mid = (low + high) >> 1;
      if (compareNewestFirst(of(list[mid]), h) < 0) {
        low = mid + 1;
      } else {
        high = mid;
      }
    }
    return low;
  }
}
