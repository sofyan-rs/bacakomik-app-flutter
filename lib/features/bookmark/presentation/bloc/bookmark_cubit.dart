import 'package:bacakomik_app/core/domain/entities/comic_details.dart';
import 'package:bacakomik_app/core/error/failures.dart';
import 'package:bacakomik_app/core/usecase/usecase.dart';
import 'package:bacakomik_app/core/utils/clock.dart';
import 'package:bacakomik_app/features/bookmark/domain/entities/bookmark.dart';
import 'package:bacakomik_app/features/bookmark/domain/usecases/bookmark_usecases.dart';
import 'package:bacakomik_app/features/bookmark/domain/usecases/migrate_comic.dart';
import 'package:bacakomik_app/features/bookmark/domain/usecases/refresh_bookmarks.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

/// Bookmarked comics, newest [Bookmark.updatedDate] first.
@injectable
class BookmarkCubit extends Cubit<List<Bookmark>> {
  BookmarkCubit(
    this._getBookmarks,
    this._saveBookmarks,
    this._removeBookmarks,
    this._refreshBookmarks,
    this._migrateComic,
    this._clock,
  ) : super(const []);

  final GetBookmarks _getBookmarks;
  final SaveBookmarks _saveBookmarks;
  final RemoveBookmarks _removeBookmarks;
  final RefreshBookmarks _refreshBookmarks;
  final MigrateComic _migrateComic;
  final Clock _clock;

  Future<void> load() async {
    final result = await _getBookmarks(const NoParams());
    result.fold(_log, emit);
  }

  Future<void> addBookmark(ComicDetails comic, String slug) => _thenReload(
    _saveBookmarks([
      Bookmark(slug: slug, comicDetails: comic, updatedDate: _clock.now()),
    ]),
  );

  Future<void> removeBookmark(String slug) => removeBookmarkList([slug]);

  Future<void> removeBookmarkList(List<String> slugs) =>
      _thenReload(_removeBookmarks([...slugs]));

  /// Pull-to-refresh: checks every bookmark for new chapters.
  Future<void> updateBookmarkList() =>
      _thenReload(_refreshBookmarks(const NoParams()));

  bool isBookmark(String slug) => state.any((b) => b.slug == slug);

  /// Bookmarks of the same series from other sources, by title.
  List<Bookmark> sameSeriesAs(String slug, String title) =>
      sameSeries(state, slug, title);

  /// Moves the bookmark and read history of [from] to [to]. The caller
  /// reloads history.
  Future<void> migrate({
    required String from,
    required String to,
    required ComicDetails details,
  }) => _thenReload(_migrateComic((from: from, to: to, details: details)));

  /// Bookmarks whose title contains [keyword] (case-insensitive on title).
  List<Bookmark> searchBookmark(String keyword) => state
      .where((b) => b.comicDetails.title.toLowerCase().contains(keyword))
      .toList();

  Future<void> _thenReload(Future<Either<Failure, Unit>> action) async {
    (await action).fold(_log, (_) {});
    await load();
  }

  void _log(Failure failure) => debugPrint('BookmarkCubit: $failure');
}
