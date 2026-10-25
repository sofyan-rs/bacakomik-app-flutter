import 'package:bacakomik_app/core/error/failures.dart';
import 'package:bacakomik_app/core/usecase/usecase.dart';
import 'package:bacakomik_app/core/utils/clock.dart';
import 'package:bacakomik_app/features/bookmark/domain/entities/bookmark.dart';
import 'package:bacakomik_app/features/bookmark/domain/repositories/bookmark_repository.dart';
import 'package:bacakomik_app/features/comic_detail/domain/repositories/comic_detail_repository.dart';
import 'package:bacakomik_app/features/migration/domain/usecases/apply_pending_reads.dart';
import 'package:bacakomik_app/features/migration/domain/usecases/import_library.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

/// Re-fetches one bookmarked comic. When its chapter count changed it gets
/// the new details and moves to the top ([Bookmark.updatedDate] = now). An
/// imported placeholder always gets the loaded details; it moves up only
/// when the source has more chapters than the imported list.
/// A comic that fails to load is left unchanged. Reading progress an import
/// left for it is applied.
@injectable
class RefreshBookmark implements UseCase<RefreshResult, Bookmark> {
  const RefreshBookmark(
    this._bookmarks,
    this._comicDetails,
    this._applyPendingReads,
    this._clock,
  );

  final BookmarkRepository _bookmarks;
  final ComicDetailRepository _comicDetails;
  final ApplyPendingReads _applyPendingReads;
  final Clock _clock;

  @override
  Future<Either<Failure, RefreshResult>> call(Bookmark bookmark) async {
    final details = await _comicDetails.getComicDetails(bookmark.slug);
    return details.fold(
      (failure) async =>
          right((saved: null, historyChanged: false, failure: failure)),
      (fresh) async {
        final imported = bookmark.comicDetails.isPlaceholder;
        final applied = await _applyPendingReads((
          key: bookmark.slug,
          details: fresh,
        ), imported: imported);
        if (applied case Left(value: final failure)) return left(failure);
        final historyChanged = applied.getOrElse((_) => false);
        final grew =
            fresh.chapters.length != bookmark.comicDetails.chapters.length;
        // An imported comic may come with its chapter list already: it gets
        // the loaded details anyway, moving up only for new chapters.
        final moved = imported
            ? fresh.chapters.length > bookmark.comicDetails.chapters.length
            : grew;
        if (!grew && !imported) {
          return right((
            saved: null,
            historyChanged: historyChanged,
            failure: null,
          ));
        }
        final updated = bookmark.copyWith(
          comicDetails: fresh,
          updatedDate: moved ? _clock.now() : bookmark.updatedDate,
        );
        final saved = await _bookmarks.saveBookmarks([updated]);
        return saved.map(
          (_) =>
              (saved: updated, historyChanged: historyChanged, failure: null),
        );
      },
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
