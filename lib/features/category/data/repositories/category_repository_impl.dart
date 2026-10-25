import 'package:bacakomik_app/core/error/failures.dart';
import 'package:bacakomik_app/core/storage/library_journal.dart';
import 'package:bacakomik_app/core/storage/local_call.dart';
import 'package:bacakomik_app/features/category/data/datasources/category_local_data_source.dart';
import 'package:bacakomik_app/features/category/data/models/category_model.dart';
import 'package:bacakomik_app/features/category/domain/entities/category.dart';
import 'package:bacakomik_app/features/category/domain/repositories/category_repository.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: CategoryRepository)
class CategoryRepositoryImpl implements CategoryRepository {
  const CategoryRepositoryImpl(this._local, this._journal);

  final CategoryLocalDataSource _local;
  final LibraryJournal _journal;

  @override
  Future<Either<Failure, List<LibraryCategory>>> getCategories() => runLocal(
    () =>
        _local.getCategories().map((m) => m.toEntity()).toList()
          ..sort((a, b) => a.order.compareTo(b.order)),
  );

  @override
  Future<Either<Failure, Unit>> saveCategories(
    List<LibraryCategory> categories,
  ) => runLocal(() async {
    await _local.putCategories(
      categories.map(CategoryModel.fromEntity).toList(),
    );
    await _journal.recordSaved(
      LibraryKind.category,
      categories.map((c) => c.id),
    );
    return unit;
  });

  @override
  Future<Either<Failure, Unit>> deleteCategories(List<String> ids) =>
      runLocal(() async {
        await _local.deleteCategories(ids);
        await _journal.recordDeleted(LibraryKind.category, ids);
        return unit;
      });

  @override
  Future<Either<Failure, Map<String, ComicCategories>>> getComicCategories() =>
      runLocal(
        () => {
          for (final m in _local.getComicCategories()) m.slug: m.toEntity(),
        },
      );

  /// Never deleted, only replaced (an empty list means none), so no
  /// deletion is journaled; the save still triggers a sync.
  @override
  Future<Either<Failure, Unit>> saveComicCategories(
    List<ComicCategories> entries,
  ) => runLocal(() async {
    await _local.putComicCategories(
      entries.map(ComicCategoriesModel.fromEntity).toList(),
    );
    await _journal.recordSaved(
      LibraryKind.comicCategories,
      entries.map((e) => e.slug),
    );
    return unit;
  });
}
