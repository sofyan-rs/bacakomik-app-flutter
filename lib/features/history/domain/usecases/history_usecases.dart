import 'package:bacakomik_app/core/error/failures.dart';
import 'package:bacakomik_app/core/usecase/usecase.dart';
import 'package:bacakomik_app/features/history/domain/entities/read_history.dart';
import 'package:bacakomik_app/features/history/domain/repositories/history_repository.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

@injectable
class GetHistory implements UseCase<List<ReadHistory>, NoParams> {
  const GetHistory(this._repository);

  final HistoryRepository _repository;

  @override
  Future<Either<Failure, List<ReadHistory>>> call(NoParams params) =>
      _repository.getHistory();
}

/// Inserts or replaces entries by chapter slug.
@injectable
class SaveHistory implements UseCase<Unit, List<ReadHistory>> {
  const SaveHistory(this._repository);

  final HistoryRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(List<ReadHistory> history) =>
      _repository.saveHistory(history);
}

/// Params: chapter slugs to remove.
@injectable
class RemoveHistory implements UseCase<Unit, List<String>> {
  const RemoveHistory(this._repository);

  final HistoryRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(List<String> slugs) =>
      _repository.removeHistory(slugs);
}

/// Params: series slug whose history is removed.
@injectable
class RemoveComicHistory implements UseCase<Unit, String> {
  const RemoveComicHistory(this._repository);

  final HistoryRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(String comicSlug) =>
      _repository.removeComicHistory(comicSlug);
}

@injectable
class ClearHistory implements UseCase<Unit, NoParams> {
  const ClearHistory(this._repository);

  final HistoryRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(NoParams params) =>
      _repository.clearHistory();
}
