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
  List<ReadHistory> get newestFirst =>
      [...this]..sort((a, b) => b.readDate.compareTo(a.readDate));

  ReadHistory? get latest => _newest(this);

  ReadHistory? latestOf(String comicSlug) =>
      _newest(where((h) => h.comicSlug == comicSlug));

  int countOf(String comicSlug) =>
      where((h) => h.comicSlug == comicSlug).length;

  bool containsChapter(String slug) => any((h) => h.slug == slug);

  /// Newest entry per comic, newest comic first.
  List<ComicLatestHistory> get latestPerComic => HistoryIndex(this).perComic;
}

ReadHistory? _newest(Iterable<ReadHistory> history) {
  ReadHistory? newest;
  for (final h in history) {
    if (newest == null || h.readDate.isAfter(newest.readDate)) newest = h;
  }
  return newest;
}

/// Lookups over one history list, built in a single pass so `build` methods
/// can query per row without rescanning or resorting the history.
class HistoryIndex {
  HistoryIndex(List<ReadHistory> history) {
    for (final h in history.newestFirst) {
      _chapters[h.slug] = h;
      _counts.update(h.comicSlug, (n) => n + 1, ifAbsent: () => 1);
      if (!_latest.containsKey(h.comicSlug)) {
        _latest[h.comicSlug] = h;
        perComic.add(
          ComicLatestHistory(
            comicSlug: h.comicSlug,
            comicDetails: h.comicDetails,
            latestHistory: h,
          ),
        );
      }
    }
  }

  final _chapters = <String, ReadHistory>{};
  final _counts = <String, int>{};
  final _latest = <String, ReadHistory>{};

  /// Newest entry per comic, newest comic first.
  final perComic = <ComicLatestHistory>[];

  ReadHistory? get latest => perComic.firstOrNull?.latestHistory;

  ReadHistory? latestOf(String comicSlug) => _latest[comicSlug];

  int countOf(String comicSlug) => _counts[comicSlug] ?? 0;

  bool containsChapter(String slug) => _chapters.containsKey(slug);

  /// The entry of one chapter, finished or not.
  ReadHistory? chapter(String slug) => _chapters[slug];

  bool isFinished(String slug) => _chapters[slug]?.isFinished ?? false;
}
