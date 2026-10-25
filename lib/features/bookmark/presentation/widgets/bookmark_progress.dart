import 'package:bacakomik_app/features/bookmark/domain/entities/bookmark.dart';
import 'package:bacakomik_app/features/comic_detail/presentation/widgets/chapter_date.dart';

enum BookmarkFilter { all, updated, finished }

/// A bookmark with how many of its chapters are in the history, and the
/// dates it can be sorted by (see `sortBookmarks`).
class BookmarkProgress {
  BookmarkProgress(this.bookmark, this.read, {this.lastRead})
    : latestChapter = latestChapterOf(bookmark);

  final Bookmark bookmark;

  /// Chapters of the comic read to the end or marked read, in any order.
  /// Zero when none is.
  final int read;

  /// When a chapter of the comic was last opened; null if never.
  final DateTime? lastRead;

  /// Release time of the newest chapter, see [latestChapterOf].
  final DateTime latestChapter;

  /// When the comic was bookmarked; [Bookmark.updatedDate] for bookmarks
  /// saved before that was stored.
  DateTime get added => bookmark.addedDate ?? bookmark.updatedDate;

  int get total => bookmark.comicDetails.chapters.length;

  /// Chapters not read yet (the count badge), also for comics never opened.
  int get newChapters => total - read;

  bool get hasUpdate => newChapters > 0;

  /// Every chapter read (not the comic's own Completed status).
  bool get isFinished => total > 0 && read >= total;

  bool matches(BookmarkFilter filter) => switch (filter) {
    BookmarkFilter.all => true,
    BookmarkFilter.updated => hasUpdate,
    BookmarkFilter.finished => isFinished,
  };

  /// [isRead] tells whether a chapter slug is finished, e.g.
  /// `HistoryIndex.isFinished`. [lastReadOf] gives when a comic was last
  /// read, e.g. from `HistoryIndex.latestOf`.
  static List<BookmarkProgress> of(
    List<Bookmark> bookmarks,
    bool Function(String chapterSlug) isRead, {
    DateTime? Function(String comicSlug)? lastReadOf,
  }) => [
    for (final bookmark in bookmarks)
      BookmarkProgress(
        bookmark,
        bookmark.comicDetails.chapters.where((c) => isRead(c.slug)).length,
        lastRead: lastReadOf?.call(bookmark.slug),
      ),
  ];

  /// The newest release date among [bookmark]'s chapters. Chapter dates
  /// are text made when the chapter list was fetched ("3 h ago",
  /// "01/02/2025"), so relative ones count back from
  /// [Bookmark.updatedDate], when the stored list was saved. With no
  /// readable date (e.g. `-`, or no chapters yet) it is
  /// [Bookmark.updatedDate] itself.
  static DateTime latestChapterOf(Bookmark bookmark) {
    DateTime? latest;
    for (final chapter in bookmark.comicDetails.chapters) {
      final date = ChapterDate.parse(
        chapter.date,
        madeAt: bookmark.updatedDate,
      );
      if (date != null && (latest == null || date.isAfter(latest))) {
        latest = date;
      }
    }
    return latest ?? bookmark.updatedDate;
  }
}
