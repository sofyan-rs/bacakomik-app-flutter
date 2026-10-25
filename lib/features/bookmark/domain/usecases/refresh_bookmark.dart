import 'package:bacakomik_app/core/error/failures.dart';
import 'package:bacakomik_app/core/usecase/usecase.dart';
import 'package:bacakomik_app/core/utils/clock.dart';
import 'package:bacakomik_app/features/bookmark/domain/entities/bookmark.dart';
import 'package:bacakomik_app/features/bookmark/domain/repositories/bookmark_repository.dart';
import 'package:bacakomik_app/features/comic_detail/domain/repositories/comic_detail_repository.dart';
import 'package:bacakomik_app/features/migration/domain/usecases/apply_pending_reads.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

/// Re-fetches one bookmarked comic. When its chapter count changed it gets
/// the new details and moves to the top ([Bookmark.updatedDate] = now).
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
      (_) async => right((updated: false, historyChanged: false)),
      (fresh) async {
        final applied = await _applyPendingReads((
          key: bookmark.slug,
          details: fresh,
        ));
        if (applied case Left(value: final failure)) return left(failure);
        final historyChanged = applied.getOrElse((_) => false);
        if (fresh.chapters.length == bookmark.comicDetails.chapters.length) {
          return right((updated: false, historyChanged: historyChanged));
        }
        final saved = await _bookmarks.saveBookmarks([
          bookmark.copyWith(comicDetails: fresh, updatedDate: _clock.now()),
        ]);
        return saved.map(
          (_) => (updated: true, historyChanged: historyChanged),
        );
      },
    );
  }
}

/// [updated]: new chapters were found. [historyChanged]: imported reading
/// progress was written to the history.
typedef RefreshResult = ({bool updated, bool historyChanged});
