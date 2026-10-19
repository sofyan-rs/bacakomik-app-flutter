import 'package:bacakomik_app/core/error/failures.dart';
import 'package:bacakomik_app/core/usecase/usecase.dart';
import 'package:bacakomik_app/core/utils/clock.dart';
import 'package:bacakomik_app/features/bookmark/domain/entities/bookmark.dart';
import 'package:bacakomik_app/features/bookmark/domain/repositories/bookmark_repository.dart';
import 'package:bacakomik_app/features/comic_detail/domain/repositories/comic_detail_repository.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

/// Re-fetches every bookmarked comic. Bookmarks whose chapter count changed
/// get the new details and move to the top ([Bookmark.updatedDate] = now).
/// Comics that fail to load are left unchanged.
@injectable
class RefreshBookmarks implements UseCase<Unit, NoParams> {
  const RefreshBookmarks(this._bookmarks, this._comicDetails, this._clock);

  final BookmarkRepository _bookmarks;
  final ComicDetailRepository _comicDetails;
  final Clock _clock;

  @override
  Future<Either<Failure, Unit>> call(NoParams params) async {
    final current = await _bookmarks.getBookmarks();
    return current.fold(left, (bookmarks) async {
      final updated = <Bookmark>[];
      // Sequential on purpose: keeps the API load the same as before.
      for (final bookmark in bookmarks) {
        final details = await _comicDetails.getComicDetails(bookmark.slug);
        details.fold((_) {}, (fresh) {
          if (fresh.chapters.length != bookmark.comicDetails.chapters.length) {
            updated.add(bookmark.copyWith(
              comicDetails: fresh,
              updatedDate: _clock.now(),
            ));
          }
        });
      }
      if (updated.isEmpty) return right(unit);
      return _bookmarks.saveBookmarks(updated);
    });
  }
}
