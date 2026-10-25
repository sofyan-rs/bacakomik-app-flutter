import 'package:bacakomik_app/core/error/failures.dart';
import 'package:bacakomik_app/features/bookmark/domain/entities/bookmark.dart';
import 'package:fpdart/fpdart.dart';

abstract interface class BookmarkRepository {
  /// Newest [Bookmark.updatedDate] first, equal dates by slug
  /// ([compareBookmarksNewestFirst]).
  Future<Either<Failure, List<Bookmark>>> getBookmarks();

  /// One bookmark by slug, without reading the others; null when absent.
  Future<Either<Failure, Bookmark?>> getBookmark(String slug);

  /// Inserts or replaces bookmarks by slug.
  Future<Either<Failure, Unit>> saveBookmarks(List<Bookmark> bookmarks);

  Future<Either<Failure, Unit>> removeBookmarks(List<String> slugs);
}
