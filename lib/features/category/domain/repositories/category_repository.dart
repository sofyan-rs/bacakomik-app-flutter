import 'package:bacakomik_app/core/error/failures.dart';
import 'package:bacakomik_app/features/category/domain/entities/category.dart';
import 'package:fpdart/fpdart.dart';

abstract interface class CategoryRepository {
  /// Lowest [LibraryCategory.order] first.
  Future<Either<Failure, List<LibraryCategory>>> getCategories();

  /// Inserts or replaces categories by id.
  Future<Either<Failure, Unit>> saveCategories(
    List<LibraryCategory> categories,
  );

  Future<Either<Failure, Unit>> deleteCategories(List<String> ids);

  /// Categories per comic key.
  Future<Either<Failure, Map<String, ComicCategories>>> getComicCategories();

  /// Inserts or replaces entries by slug.
  Future<Either<Failure, Unit>> saveComicCategories(
    List<ComicCategories> entries,
  );
}
