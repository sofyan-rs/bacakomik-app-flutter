import 'package:bacakomik_app/core/error/failures.dart';
import 'package:bacakomik_app/core/usecase/usecase.dart';
import 'package:bacakomik_app/features/category/domain/entities/category.dart';
import 'package:bacakomik_app/features/category/domain/repositories/category_repository.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

/// Categories, lowest [LibraryCategory.order] first.
@injectable
class GetCategories implements UseCase<List<LibraryCategory>, NoParams> {
  const GetCategories(this._repository);

  final CategoryRepository _repository;

  @override
  Future<Either<Failure, List<LibraryCategory>>> call(NoParams params) =>
      _repository.getCategories();
}

/// Inserts or replaces categories by id.
@injectable
class SaveCategories implements UseCase<Unit, List<LibraryCategory>> {
  const SaveCategories(this._repository);

  final CategoryRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(List<LibraryCategory> categories) =>
      _repository.saveCategories(categories);
}

/// Params: category ids. Comics in them are left in their other categories.
@injectable
class DeleteCategories implements UseCase<Unit, List<String>> {
  const DeleteCategories(this._repository);

  final CategoryRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(List<String> ids) =>
      _repository.deleteCategories(ids);
}

/// Categories per comic key.
@injectable
class GetComicCategories
    implements UseCase<Map<String, ComicCategories>, NoParams> {
  const GetComicCategories(this._repository);

  final CategoryRepository _repository;

  @override
  Future<Either<Failure, Map<String, ComicCategories>>> call(NoParams params) =>
      _repository.getComicCategories();
}

/// Inserts or replaces the categories of comics by slug.
@injectable
class SaveComicCategories implements UseCase<Unit, List<ComicCategories>> {
  const SaveComicCategories(this._repository);

  final CategoryRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(List<ComicCategories> entries) =>
      _repository.saveComicCategories(entries);
}
