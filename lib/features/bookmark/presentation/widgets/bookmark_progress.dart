import 'package:bacakomik_app/features/bookmark/domain/entities/bookmark.dart';

enum BookmarkFilter { all, updated, finished }

/// A bookmark with how many of its chapters are in the history.
class BookmarkProgress {
  const BookmarkProgress(this.bookmark, this.read);

  final Bookmark bookmark;

  /// Chapters of the comic marked read, in any order. Zero when the comic
  /// has never been opened.
  final int read;

  int get total => bookmark.comicDetails.chapters.length;

  /// Chapters not read yet (the `+N` badge). Comics never opened show no
  /// badge.
  int get newChapters => read == 0 ? 0 : total - read;

  bool get hasUpdate => newChapters > 0;

  /// Every chapter read (not the comic's own Completed status).
  bool get isFinished => total > 0 && read >= total;

  bool matches(BookmarkFilter filter) => switch (filter) {
    BookmarkFilter.all => true,
    BookmarkFilter.updated => hasUpdate,
    BookmarkFilter.finished => isFinished,
  };

  /// [isRead] tells whether a chapter slug is in the history, e.g.
  /// `HistoryIndex.containsChapter`.
  static List<BookmarkProgress> of(
    List<Bookmark> bookmarks,
    bool Function(String chapterSlug) isRead,
  ) => [
    for (final bookmark in bookmarks)
      BookmarkProgress(
        bookmark,
        bookmark.comicDetails.chapters.where((c) => isRead(c.slug)).length,
      ),
  ];
}
