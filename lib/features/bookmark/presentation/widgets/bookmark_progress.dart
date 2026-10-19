import 'package:bacakomik_app/features/bookmark/domain/entities/bookmark.dart';
import 'package:bacakomik_app/features/history/domain/entities/read_history.dart';
import 'package:bacakomik_app/features/history/domain/entities/read_progress.dart';

enum BookmarkFilter { all, updated, finished }

/// A bookmark with its read progress from the history.
class BookmarkProgress {
  const BookmarkProgress(this.bookmark, this.progress);

  final Bookmark bookmark;

  /// Null when no chapter of the comic has been read.
  final ReadProgress? progress;

  /// Chapters released after the last read one (the `+N` badge). Comics
  /// never opened show no badge.
  int get newChapters => progress?.unread ?? 0;

  bool get hasUpdate => newChapters > 0;

  /// Every chapter read (REDESIGN_PLAN D1).
  bool get isFinished => progress?.isFinished ?? false;

  bool matches(BookmarkFilter filter) => switch (filter) {
    BookmarkFilter.all => true,
    BookmarkFilter.updated => hasUpdate,
    BookmarkFilter.finished => isFinished,
  };

  /// [latestOf] returns the newest read chapter of a comic, e.g.
  /// `HistoryIndex.latestOf`.
  static List<BookmarkProgress> of(
    List<Bookmark> bookmarks,
    ReadHistory? Function(String comicSlug) latestOf,
  ) => [
    for (final bookmark in bookmarks)
      BookmarkProgress(bookmark, switch (latestOf(bookmark.slug)) {
        final latest? => ReadProgress.of(
          bookmark.comicDetails,
          latest.chapterNumber,
        ),
        null => null,
      }),
  ];
}
