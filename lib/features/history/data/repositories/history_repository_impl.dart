import 'package:bacakomik_app/core/data/models/comic_details_model.dart';
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

  /// Joins entries with their comic. An entry whose comic record is missing
  /// cannot be shown and is skipped.
  @override
  Future<Either<Failure, List<ReadHistory>>> getHistory() => runLocal(() {
    final comics = _local.getComics();
    return [
      for (final entry in _local.getEntries())
        if (comics[entry.comicSlug] case final comic?)
          entry.toEntity(comic.comicDetails.toEntity()),
    ].newestFirst;
  });

  /// Stores the entries, and each comic's details once (the last given).
  @override
  Future<Either<Failure, Unit>> saveHistory(List<ReadHistory> history) =>
      runLocal(() async {
        await _local.putEntries(
          history.map(ReadHistoryModel.fromEntity).toList(),
        );
        final comics = {
          for (final h in history)
            h.comicSlug: HistoryComicModel(
              slug: h.comicSlug,
              comicDetails: ComicDetailsModel.fromEntity(h.comicDetails),
            ),
        };
        await _local.putComics(comics.values.toList());
        return unit;
      });

  @override
  Future<Either<Failure, Unit>> removeHistory(List<String> slugs) =>
      runLocal(() async {
        await _local.deleteEntries(slugs);
        await _pruneComics();
        return unit;
      });

  @override
  Future<Either<Failure, Unit>> removeComicHistory(String comicSlug) =>
      runLocal(() async {
        final slugs = [
          for (final entry in _local.getEntries())
            if (entry.comicSlug == comicSlug) entry.slug,
        ];
        await _local.deleteEntries(slugs);
        await _local.deleteComics([comicSlug]);
        return unit;
      });

  @override
  Future<Either<Failure, Unit>> clearHistory() => runLocal(() async {
    await _local.clear();
    return unit;
  });

  /// Drops comic records that no entry refers to any more.
  Future<void> _pruneComics() async {
    final used = {for (final e in _local.getEntries()) e.comicSlug};
    final unused = [
      for (final slug in _local.getComics().keys)
        if (!used.contains(slug)) slug,
    ];
    if (unused.isNotEmpty) await _local.deleteComics(unused);
  }
}
