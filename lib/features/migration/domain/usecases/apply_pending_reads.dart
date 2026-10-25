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

/// Marks read the chapters an import said were read: every chapter of
/// [ComicLoadedParams.details] numbered up to the pending last read one.
/// Chapters already in the history keep their entry. Waits while the
/// chapter list is empty. Returns whether history was written.
@injectable
class ApplyPendingReads implements UseCase<bool, ComicLoadedParams> {
  const ApplyPendingReads(this._pending, this._history, this._clock);

  final PendingReadRepository _pending;
  final HistoryRepository _history;
  final Clock _clock;

  @override
  Future<Either<Failure, bool>> call(ComicLoadedParams params) async {
    final (:key, :details) = params;
    if (details.chapters.isEmpty) return right(false);
    final pending = await _pending.lastReadOf(key);
    if (pending case Left(value: final failure)) return left(failure);
    final lastRead = pending.getOrElse((_) => null);
    if (lastRead == null) return right(false);

    final limit = num.tryParse(lastRead);
    final history = await _history.getHistory();
    if (history case Left(value: final failure)) return left(failure);
    final index = HistoryIndex(history.getOrElse((_) => const []));
    final now = _clock.now();
    // Chapters come newest first; the last read one gets the newest time,
    // so "Continue reading" points at it.
    final read = [
      if (limit != null)
        for (final (i, chapter) in details.chapters.indexed)
          if (num.tryParse(chapter.number) case final n?
              when n <= limit && !index.containsChapter(chapter.slug))
            ReadHistory(
              slug: chapter.slug,
              chapterNumber: chapter.number,
              readDate: now.subtract(Duration(milliseconds: i)),
              comicDetails: details,
              comicSlug: key,
            ),
    ];
    if (read.isNotEmpty) {
      final saved = await _history.saveHistory(read);
      if (saved case Left(value: final failure)) return left(failure);
    }
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
    if (bookmark != null && bookmark.comicDetails.isPlaceholder) {
      final saved = await _bookmarks.saveBookmarks([
        bookmark.copyWith(comicDetails: details),
      ]);
      if (saved case Left(value: final failure)) return left(failure);
    }
    return _applyPendingReads(params);
  }
}
