import 'package:bacakomik_app/core/error/failures.dart';
import 'package:bacakomik_app/features/history/domain/entities/read_history.dart';
import 'package:fpdart/fpdart.dart';

abstract interface class HistoryRepository {
  /// Newest [ReadHistory.readDate] first.
  Future<Either<Failure, List<ReadHistory>>> getHistory();

  /// Inserts or replaces entries by chapter slug.
  Future<Either<Failure, Unit>> saveHistory(List<ReadHistory> history);

  /// Removes entries by chapter slug.
  Future<Either<Failure, Unit>> removeHistory(List<String> slugs);

  /// Removes every entry of one comic.
  Future<Either<Failure, Unit>> removeComicHistory(String comicSlug);

  Future<Either<Failure, Unit>> clearHistory();
}
