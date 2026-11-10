import 'package:yoru/core/error/failures.dart';
import 'package:yoru/core/usecase/usecase.dart';
import 'package:yoru/features/bookmark/domain/entities/bookmark.dart';
import 'package:yoru/features/bookmark/domain/repositories/bookmark_repository.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

@injectable
class GetBookmarks implements UseCase<List<Bookmark>, NoParams> {
  const GetBookmarks(this._repository);

  final BookmarkRepository _repository;

  @override
  Future<Either<Failure, List<Bookmark>>> call(NoParams params) =>
      _repository.getBookmarks();
}

/// Inserts or replaces bookmarks by slug.
@injectable
class SaveBookmarks implements UseCase<Unit, List<Bookmark>> {
  const SaveBookmarks(this._repository);

  final BookmarkRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(List<Bookmark> bookmarks) =>
      _repository.saveBookmarks(bookmarks);
}

/// Params: series slugs to remove.
@injectable
class RemoveBookmarks implements UseCase<Unit, List<String>> {
  const RemoveBookmarks(this._repository);

  final BookmarkRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(List<String> slugs) =>
      _repository.removeBookmarks(slugs);
}
