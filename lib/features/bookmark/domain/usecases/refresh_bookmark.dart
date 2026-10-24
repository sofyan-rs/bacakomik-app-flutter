import 'package:bacakomik_app/core/error/failures.dart';
import 'package:bacakomik_app/core/usecase/usecase.dart';
import 'package:bacakomik_app/core/utils/clock.dart';
import 'package:bacakomik_app/features/bookmark/domain/entities/bookmark.dart';
import 'package:bacakomik_app/features/bookmark/domain/repositories/bookmark_repository.dart';
import 'package:bacakomik_app/features/comic_detail/domain/repositories/comic_detail_repository.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

/// Re-fetches one bookmarked comic. When its chapter count changed it gets
/// the new details and moves to the top ([Bookmark.updatedDate] = now).
/// A comic that fails to load is left unchanged. Returns whether it changed.
@injectable
class RefreshBookmark implements UseCase<bool, Bookmark> {
  const RefreshBookmark(this._bookmarks, this._comicDetails, this._clock);

  final BookmarkRepository _bookmarks;
  final ComicDetailRepository _comicDetails;
  final Clock _clock;

  @override
  Future<Either<Failure, bool>> call(Bookmark bookmark) async {
    final details = await _comicDetails.getComicDetails(bookmark.slug);
    return details.fold((_) async => right(false), (fresh) async {
      if (fresh.chapters.length == bookmark.comicDetails.chapters.length) {
        return right(false);
      }
      final saved = await _bookmarks.saveBookmarks([
        bookmark.copyWith(comicDetails: fresh, updatedDate: _clock.now()),
      ]);
      return saved.map((_) => true);
    });
  }
}
