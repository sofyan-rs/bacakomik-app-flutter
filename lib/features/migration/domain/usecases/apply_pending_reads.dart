import 'package:bacakomik_app/core/domain/entities/comic_details.dart';
import 'package:bacakomik_app/core/error/failures.dart';
import 'package:bacakomik_app/core/usecase/usecase.dart';
import 'package:bacakomik_app/core/utils/clock.dart';
import 'package:bacakomik_app/features/bookmark/domain/repositories/bookmark_repository.dart';
import 'package:bacakomik_app/features/history/domain/entities/read_history.dart';
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
    // Chapters come newest first; without a date the last read one gets the
    // newest time, so "Continue reading" points at it.
    final read = [
      if (pending != null)
        for (final (i, chapter) in details.chapters.indexed)
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
    return (await _pending.remove(key)).map((_) => read.isNotEmpty);
  }
}

/// Run when a comic's details load from its source. A bookmark stored by an
/// import ([ComicDetailsX.isPlaceholder]) gets the loaded details, keeping
/// its place, and pending reads are applied. Returns whether the history
/// changed.
@injectable
class CompleteImportedComic implements UseCase<bool, ComicLoadedParams> {
  const CompleteImportedComic(this._bookmarks, this._applyPendingReads);

  final BookmarkRepository _bookmarks;
  final ApplyPendingReads _applyPendingReads;

  @override
  Future<Either<Failure, bool>> call(ComicLoadedParams params) async {
    final (:key, :details) = params;
    if (details.isPlaceholder) return right(false);
    final bookmarks = await _bookmarks.getBookmarks();
    if (bookmarks case Left(value: final failure)) return left(failure);
    final bookmark = bookmarks
        .getOrElse((_) => const [])
        .where((b) => b.slug == key)
        .firstOrNull;
    final imported = bookmark?.comicDetails.isPlaceholder ?? false;
    if (bookmark != null && imported) {
      final saved = await _bookmarks.saveBookmarks([
        bookmark.copyWith(comicDetails: details),
      ]);
      if (saved case Left(value: final failure)) return left(failure);
    }
    return _applyPendingReads(params, imported: imported);
  }
}
