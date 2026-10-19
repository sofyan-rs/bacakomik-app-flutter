import 'package:bacakomik_app/core/domain/entities/comic_details.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'read_history.freezed.dart';

/// One read chapter.
@freezed
abstract class ReadHistory with _$ReadHistory {
  const factory ReadHistory({
    /// Chapter slug (`seriesSlug/number`), unique per entry.
    required String slug,
    required String chapterNumber,
    required DateTime readDate,
    required ComicDetails comicDetails,

    /// Series slug.
    required String comicSlug,
  }) = _ReadHistory;
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

/// Read-only queries over a history list in any order.
extension ReadHistoryQueries on List<ReadHistory> {
  List<ReadHistory> get newestFirst =>
      [...this]..sort((a, b) => b.readDate.compareTo(a.readDate));

  ReadHistory? get latest => isEmpty ? null : newestFirst.first;

  ReadHistory? latestOf(String comicSlug) {
    for (final history in newestFirst) {
      if (history.comicSlug == comicSlug) return history;
    }
    return null;
  }

  int countOf(String comicSlug) =>
      where((h) => h.comicSlug == comicSlug).length;

  bool containsChapter(String slug) => any((h) => h.slug == slug);

  /// Newest entry per comic, newest comic first.
  List<ComicLatestHistory> get latestPerComic {
    final seen = <String>{};
    return [
      for (final history in newestFirst)
        if (seen.add(history.comicSlug))
          ComicLatestHistory(
            comicSlug: history.comicSlug,
            comicDetails: history.comicDetails,
            latestHistory: history,
          ),
    ];
  }
}
