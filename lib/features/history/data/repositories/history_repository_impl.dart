import 'package:bacakomik_app/core/error/failures.dart';
import 'package:bacakomik_app/core/storage/local_call.dart';
import 'package:bacakomik_app/features/history/data/datasources/history_local_data_source.dart';
import 'package:bacakomik_app/features/history/data/models/read_history_model.dart';
import 'package:bacakomik_app/features/history/domain/entities/read_history.dart';
import 'package:bacakomik_app/features/history/domain/repositories/history_repository.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: HistoryRepository)
class HistoryRepositoryImpl implements HistoryRepository {
  const HistoryRepositoryImpl(this._local);

  final HistoryLocalDataSource _local;

  @override
  Future<Either<Failure, List<ReadHistory>>> getHistory() =>
      runLocal(() => _local.getAll().map((m) => m.toEntity()).toList().newestFirst);

  @override
  Future<Either<Failure, Unit>> saveHistory(List<ReadHistory> history) =>
      runLocal(() async {
        await _local.putAll(history.map(ReadHistoryModel.fromEntity).toList());
        return unit;
      });

  @override
  Future<Either<Failure, Unit>> removeHistory(List<String> slugs) =>
      runLocal(() async {
        await _local.deleteAll(slugs);
        return unit;
      });

  @override
  Future<Either<Failure, Unit>> removeComicHistory(String comicSlug) =>
      runLocal(() async {
        final slugs = _local
            .getAll()
            .where((h) => h.comicSlug == comicSlug)
            .map((h) => h.slug)
            .toList();
        await _local.deleteAll(slugs);
        return unit;
      });

  @override
  Future<Either<Failure, Unit>> clearHistory() => runLocal(() async {
        await _local.clear();
        return unit;
      });
}
