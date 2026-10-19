import 'package:bacakomik_app/core/error/failures.dart';
import 'package:bacakomik_app/features/bookmark/domain/entities/bookmark.dart';
import 'package:fpdart/fpdart.dart';

abstract interface class BookmarkRepository {
  /// Newest [Bookmark.updatedDate] first.
  Future<Either<Failure, List<Bookmark>>> getBookmarks();

  /// Inserts or replaces bookmarks by slug.
  Future<Either<Failure, Unit>> saveBookmarks(List<Bookmark> bookmarks);

  Future<Either<Failure, Unit>> removeBookmarks(List<String> slugs);
}
