import 'package:bacakomik_app/core/error/failures.dart';
import 'package:bacakomik_app/features/history/domain/entities/read_history.dart';
import 'package:fpdart/fpdart.dart';

abstract interface class HistoryRepository {
  /// Newest [ReadHistory.readDate] first, ties by slug
  /// ([ReadHistoryQueries.newestFirst]). Entries of one comic share one
  /// [ReadHistory.comicDetails] object.
  Future<Either<Failure, List<ReadHistory>>> getHistory();

  /// Inserts or replaces entries by chapter slug. Each comic keeps the
  /// details of its last entry in [history]. A [quiet] save (the reader
  /// keeping its page) does not ask sync to run.
  Future<Either<Failure, Unit>> saveHistory(
    List<ReadHistory> history, {
    bool quiet = false,
  });

  /// Removes entries by chapter slug.
  Future<Either<Failure, Unit>> removeHistory(List<String> slugs);

  /// Removes every entry of one comic.
  Future<Either<Failure, Unit>> removeComicHistory(String comicSlug);

  /// Removes every entry of each comic.
  Future<Either<Failure, Unit>> removeComicsHistory(List<String> comicSlugs);

  Future<Either<Failure, Unit>> clearHistory();
}
