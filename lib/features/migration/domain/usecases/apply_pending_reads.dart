import 'package:bacakomik_app/core/domain/entities/comic_details.dart';
import 'package:bacakomik_app/core/error/failures.dart';
import 'package:bacakomik_app/core/usecase/usecase.dart';
import 'package:bacakomik_app/core/utils/clock.dart';
import 'package:bacakomik_app/features/bookmark/domain/entities/bookmark.dart';
import 'package:bacakomik_app/features/bookmark/domain/repositories/bookmark_repository.dart';
import 'package:bacakomik_app/features/history/domain/entities/read_history.dart';
import 'package:bacakomik_app/features/history/domain/entities/resume_chapter.dart';
import 'package:bacakomik_app/features/history/domain/repositories/history_repository.dart';
import 'package:bacakomik_app/features/migration/domain/repositories/pending_read_repository.dart';
import 'package:bacakomik_app/features/migration/domain/usecases/import_library.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

typedef ComicLoadedParams = ({String key, ComicDetails details});

/// Marks read the chapters an import said were read, matched by number
/// onto the loaded chapter list of [ComicLoadedParams.details]: the exact
/// chapters it listed, with their read dates, and every chapter up to its
/// `upTo` number (the only form older versions stored). Chapters already in
/// the history keep their entry. Waits while the chapter list is empty or
/// a placeholder's. Returns whether history was written.
///
/// With `imported` (the comic's stored details were a placeholder), the
/// comic's history, written at import with the placeholder, is given the
/// loaded details too, so it shows the cover.
@injectable
class ApplyPendingReads implements UseCase<bool, ComicLoadedParams> {
  const ApplyPendingReads(this._pending, this._history, this._clock);

  final PendingReadRepository _pending;
  final HistoryRepository _history;
  final Clock _clock;

  @override
  Future<Either<Failure, bool>> call(
    ComicLoadedParams params, {
    bool imported = false,
  }) async {
    final (:key, :details) = params;
    if (details.chapters.isEmpty || details.isPlaceholder) return right(false);
    final stored = await _pending.pendingOf(key);
    if (stored case Left(value: final failure)) return left(failure);
    final pending = stored.getOrElse((_) => null);
    if (pending == null && !imported) return right(false);

    final history = await _history.getHistory();
    if (history case Left(value: final failure)) return left(failure);
    final index = HistoryIndex(history.getOrElse((_) => const []));
    final now = _clock.now();
    // Without a date the highest numbered read chapter gets the newest time,
    // so "Continue reading" points at it.
    final read = [
      if (pending != null)
        for (final (i, chapter) in chaptersNewestFirst(
          details.chapters,
        ).indexed)
          if (pending.covers(chapter.number) &&
              !index.containsChapter(chapter.slug))
            ReadHistory(
              slug: chapter.slug,
              chapterNumber: chapter.number,
              readDate:
                  pending.readDateOf(chapter.number) ??
                  now.subtract(Duration(milliseconds: i)),
              comicDetails: details,
              comicSlug: key,
            ),
    ];
    // Entries saved with the placeholder get the loaded details (the
    // history keeps one copy per comic, the last saved).
    final latest = index.latestOf(key);
    if (read.isEmpty && latest != null && latest.comicDetails.isPlaceholder) {
      read.add(latest.copyWith(comicDetails: details));
    }
    if (read.isNotEmpty) {
      final saved = await _history.saveHistory(read);
      if (saved case Left(value: final failure)) return left(failure);
    }
    if (pending == null) return right(read.isNotEmpty);
    // An import that added to it meanwhile keeps it for the next load.
    return (await _pending.removeIfUnchanged(
      key,
      pending,
    )).map((_) => read.isNotEmpty);
  }
}

/// Run when a comic's details load. A bookmark stored by an import
/// ([ComicDetailsX.isPlaceholder]) gets the loaded details, keeping its
/// place, and pending reads are applied. With [fresh] (the details came
/// from the source, not a stored copy), any other bookmark of the comic
/// gets them too (cover, chapter count), moving to the top when the chapter
/// count changed, as a refresh in Bookmarks does. Returns the bookmark as
/// saved when it changed, and whether the history changed.
@injectable
class CompleteImportedComic
    implements UseCase<CompletedComic, ComicLoadedParams> {
  const CompleteImportedComic(
    this._bookmarks,
    this._applyPendingReads,
    this._clock,
  );

  final BookmarkRepository _bookmarks;
  final ApplyPendingReads _applyPendingReads;
  final Clock _clock;

  @override
  Future<Either<Failure, CompletedComic>> call(
    ComicLoadedParams params, {
    bool fresh = false,
  }) async {
    final (:key, :details) = params;
    if (details.isPlaceholder) {
      return right((bookmark: null, historyChanged: false));
    }
    final stored = await _bookmarks.getBookmark(key);
    if (stored case Left(value: final failure)) return left(failure);
    final bookmark = stored.getOrElse((_) => null);
    final imported = bookmark?.comicDetails.isPlaceholder ?? false;
    Bookmark? updated;
    if (bookmark != null && (imported || fresh)) {
      final now = _clock.now();
      // Read again on write: a bookmark removed meanwhile stays removed.
      final saved = await _bookmarks.updateBookmark(key, (current) {
        final old = current.comicDetails;
        if (old.isPlaceholder) return current.copyWith(comicDetails: details);
        if (!fresh || old == details) return null;
        final moved = old.chapters.length != details.chapters.length;
        return current.copyWith(
          comicDetails: details,
          updatedDate: moved ? now : current.updatedDate,
        );
      });
      if (saved case Left(value: final failure)) return left(failure);
      updated = saved.getOrElse((_) => null);
    }
    final applied = await _applyPendingReads(params, imported: imported);
    return applied.map(
      (historyChanged) => (bookmark: updated, historyChanged: historyChanged),
    );
  }
}

/// [bookmark]: the bookmark as saved with the loaded details; null when no
/// bookmark changed. [historyChanged]: the history was written.
typedef CompletedComic = ({Bookmark? bookmark, bool historyChanged});
