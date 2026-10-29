import 'package:bacakomik_app/core/domain/entities/comic_details.dart';
import 'package:bacakomik_app/core/error/failures.dart';
import 'package:bacakomik_app/core/usecase/usecase.dart';
import 'package:bacakomik_app/core/utils/clock.dart';
import 'package:bacakomik_app/features/bookmark/domain/entities/bookmark.dart';
import 'package:bacakomik_app/features/bookmark/domain/repositories/bookmark_repository.dart';
import 'package:bacakomik_app/features/bookmark/domain/usecases/merge_sources.dart';
import 'package:bacakomik_app/features/comic_detail/domain/repositories/comic_detail_repository.dart';
import 'package:bacakomik_app/features/migration/domain/usecases/apply_pending_reads.dart';
import 'package:bacakomik_app/features/migration/domain/usecases/import_library.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

/// Tells a running [RefreshBookmark] its result is no longer wanted (the
/// run was stopped, the comic timed out or was removed): it then writes
/// nothing. A request already sent cannot be taken back, so it may still
/// finish; only its writes are skipped.
class RefreshCancelToken {
  var _cancelled = false;

  bool get cancelled => _cancelled;

  void cancel() => _cancelled = true;
}

/// Re-checks one bookmarked comic, by key. Reads the stored bookmark, so a
/// comic removed since it was queued is skipped without a request.
///
/// Fetches the chapter list first; the series details are fetched only
/// when the chapter count changed or the bookmark is an imported
/// placeholder. A changed chapter count saves the new details and moves
/// the comic to the top ([Bookmark.updatedDate] = now). An imported
/// placeholder always gets the loaded details; it moves up only when the
/// source has more chapters than the imported list.
/// A comic that fails to load is left unchanged. Reading progress an import
/// left for it is applied. The save goes through
/// [BookmarkRepository.updateBookmark], so a bookmark removed while the
/// requests ran stays removed.
///
/// A merged bookmark checks every source ([FetchMergedChapters]), takes
/// its details from the first, and its read chapters follow the merged
/// list ([AlignMergedHistory]).
@injectable
class RefreshBookmark implements UseCase<RefreshResult, String> {
  const RefreshBookmark(
    this._bookmarks,
    this._comicDetails,
    this._applyPendingReads,
    this._clock,
    this._mergedChapters,
    this._alignHistory,
  );

  final BookmarkRepository _bookmarks;
  final ComicDetailRepository _comicDetails;
  final ApplyPendingReads _applyPendingReads;
  final Clock _clock;
  final FetchMergedChapters _mergedChapters;
  final AlignMergedHistory _alignHistory;

  static const _unchanged = (saved: null, historyChanged: false, failure: null);

  @override
  Future<Either<Failure, RefreshResult>> call(
    String key, {
    RefreshCancelToken? token,
  }) async {
    bool cancelled() => token?.cancelled ?? false;

    final stored = await _bookmarks.getBookmark(key);
    if (stored case Left(value: final failure)) return left(failure);
    final bookmark = stored.getOrElse((_) => null);
    if (bookmark == null || cancelled()) return right(_unchanged);

    final keys = bookmark.sourceKeys;
    final merged = bookmark.isMerged;
    final chapters = merged
        ? await _mergedChapters(keys, bookmark.comicDetails.chapters)
        : await _comicDetails.getChapters(key);
    if (chapters case Left(value: final failure)) {
      return right((saved: null, historyChanged: false, failure: failure));
    }
    if (cancelled()) return right(_unchanged);
    final fresh = chapters.getOrElse((_) => const []);
    final imported = bookmark.comicDetails.isPlaceholder;
    final grew = fresh.length != bookmark.comicDetails.chapters.length;

    final ComicDetails details;
    if (grew || imported) {
      final loaded = await _comicDetails.getSeries(keys.first, fresh);
      if (loaded case Left(value: final failure)) {
        return right((saved: null, historyChanged: false, failure: failure));
      }
      details = loaded.getOrElse((f) => throw f);
    } else {
      // Unchanged: only the chapter list is needed, to apply progress.
      details = bookmark.comicDetails.copyWith(chapters: fresh);
    }
    if (cancelled()) return right(_unchanged);

    final applied = await _applyPendingReads((
      key: key,
      details: details,
    ), imported: imported);
    if (applied case Left(value: final failure)) return left(failure);
    var historyChanged = applied.getOrElse((_) => false);
    if (merged && !cancelled()) {
      final aligned = await _alignHistory((key: key, chapters: fresh));
      if (aligned case Left(value: final failure)) return left(failure);
      historyChanged |= aligned.getOrElse((_) => false);
    }
    if ((!grew && !imported) || cancelled()) {
      return right((
        saved: null,
        historyChanged: historyChanged,
        failure: null,
      ));
    }

    final now = _clock.now();
    final saved = await _bookmarks.updateBookmark(key, (current) {
      final placeholder = current.comicDetails.isPlaceholder;
      final count = current.comicDetails.chapters.length;
      // An imported comic may come with its chapter list already: it gets
      // the loaded details anyway, moving up only for new chapters.
      final moved = placeholder ? fresh.length > count : fresh.length != count;
      if (!placeholder && fresh.length == count) return null;
      return current.copyWith(
        comicDetails: details,
        updatedDate: moved ? now : current.updatedDate,
      );
    });
    return saved.map(
      (saved) => (saved: saved, historyChanged: historyChanged, failure: null),
    );
  }
}

/// [saved]: the bookmark as saved when it changed (new chapters were found,
/// or an imported comic got its details); null when unchanged.
/// [historyChanged]: imported reading progress was written to the history.
/// [failure]: why the comic did not load; it is left as it was.
typedef RefreshResult = ({
  Bookmark? saved,
  bool historyChanged,
  Failure? failure,
});
