import 'package:bacakomik_app/features/bookmark/presentation/widgets/bookmark_progress.dart';
import 'package:bacakomik_app/features/settings/domain/entities/app_settings.dart';

/// [items] ordered by [sort] in [direction]. The sort is stable: with
/// [BookmarkSort.updated], comics with the same date keep their order in
/// [items] (the repository's, newest first), so the default reproduces the
/// order from before sorting existed. Other keys break ties by title, then
/// key. With [BookmarkSort.lastRead], comics never read go last in both
/// directions; with [BookmarkSort.unread], comics with nothing left to
/// read do.
List<BookmarkProgress> sortBookmarks(
  Iterable<BookmarkProgress> items,
  BookmarkSort sort,
  SortDirection direction,
) {
  final compare = bookmarkComparator(sort, direction);
  final indexed = items.indexed.toList()
    ..sort((a, b) {
      final order = compare(a.$2, b.$2);
      return order != 0 ? order : a.$1.compareTo(b.$1);
    });
  return [for (final (_, item) in indexed) item];
}

/// Compares two bookmarks for [sortBookmarks]; 0 means "keep their order".
Comparator<BookmarkProgress> bookmarkComparator(
  BookmarkSort sort,
  SortDirection direction,
) {
  final sign = direction == SortDirection.ascending ? 1 : -1;
  return (a, b) {
    final int order;
    if (sort == BookmarkSort.lastRead) {
      order = switch ((a.lastRead, b.lastRead)) {
        (null, null) => 0,
        (null, _) => 1,
        (_, null) => -1,
        (final x?, final y?) => sign * x.compareTo(y),
      };
    } else if (sort == BookmarkSort.unread) {
      order = switch ((a.newChapters, b.newChapters)) {
        (0, 0) => 0,
        (0, _) => 1,
        (_, 0) => -1,
        (final x, final y) => sign * x.compareTo(y),
      };
    } else {
      order =
          sign *
          switch (sort) {
            BookmarkSort.updated => a.bookmark.updatedDate.compareTo(
              b.bookmark.updatedDate,
            ),
            BookmarkSort.title => _title(a).compareTo(_title(b)),
            BookmarkSort.chapters => a.total.compareTo(b.total),
            BookmarkSort.latestChapter => a.latestChapter.compareTo(
              b.latestChapter,
            ),
            BookmarkSort.added => a.added.compareTo(b.added),
            BookmarkSort.lastRead => 0,
            BookmarkSort.unread => 0,
          };
    }
    if (order != 0 || sort == BookmarkSort.updated) return order;
    final byTitle = _title(a).compareTo(_title(b));
    return byTitle != 0 ? byTitle : a.bookmark.slug.compareTo(b.bookmark.slug);
  };
}

/// The direction an option starts in when picked: A to Z, fewest unread
/// first, otherwise the most or newest first.
SortDirection defaultDirectionOf(BookmarkSort sort) => switch (sort) {
  BookmarkSort.title || BookmarkSort.unread => SortDirection.ascending,
  _ => SortDirection.descending,
};

String _title(BookmarkProgress item) =>
    item.bookmark.comicDetails.title.toLowerCase();
