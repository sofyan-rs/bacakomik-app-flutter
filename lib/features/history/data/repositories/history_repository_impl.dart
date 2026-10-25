import 'package:bacakomik_app/core/data/models/comic_details_model.dart';
import 'package:bacakomik_app/core/domain/entities/comic_details.dart';
import 'package:bacakomik_app/core/error/failures.dart';
import 'package:bacakomik_app/core/storage/library_journal.dart';
import 'package:bacakomik_app/core/storage/local_call.dart';
import 'package:bacakomik_app/features/history/data/datasources/history_local_data_source.dart';
import 'package:bacakomik_app/features/history/data/models/read_history_model.dart';
import 'package:bacakomik_app/features/history/domain/entities/read_history.dart';
import 'package:bacakomik_app/features/history/domain/repositories/history_repository.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: HistoryRepository)
class HistoryRepositoryImpl implements HistoryRepository {
  HistoryRepositoryImpl(this._local, this._journal);

  final HistoryLocalDataSource _local;
  final LibraryJournal _journal;

  /// Per comic, the details object last saved and the stored JSON it was
  /// saved as. Saving the same object again while the record is unchanged
  /// skips encoding it (the reader saves its page with the same details).
  final _saved = <String, (ComicDetails, String?)>{};

  /// Joins entries with their comic. An entry whose comic record is missing
  /// cannot be shown and is skipped. Each comic's details are converted
  /// once and shared by its entries.
  @override
  Future<Either<Failure, List<ReadHistory>>> getHistory() => runLocal(() {
    final comics = _local.getComics();
    final details = <String, ComicDetails>{};
    return [
      for (final entry in _local.getEntries())
        if (comics[entry.comicSlug] case final comic?)
          entry.toEntity(
            details[entry.comicSlug] ??= comic.comicDetails.toEntity(),
          ),
    ].newestFirst;
  });

  /// Stores each comic's details once (the last given), then the entries:
  /// in that order, so a write cut short leaves a comic without entries
  /// rather than entries without their comic, which reads skip. A comic
  /// record that would not change is not written again.
  @override
  Future<Either<Failure, Unit>> saveHistory(
    List<ReadHistory> history, {
    bool quiet = false,
  }) => runLocal(() async {
    final comics = {for (final h in history) h.comicSlug: h.comicDetails};
    Future<void> putComics(bool Function(String slug, ComicDetails d) when) =>
        _local.putComics([
          for (final MapEntry(key: slug, value: details) in comics.entries)
            if (when(slug, details))
              HistoryComicModel(
                slug: slug,
                comicDetails: ComicDetailsModel.fromEntity(details),
              ),
        ]);
    await putComics((slug, details) => !_isStored(slug, details));
    await _local.putEntries(history.map(ReadHistoryModel.fromEntity).toList());
    // A removal running meanwhile may have pruned a comic before its new
    // entries landed: store it again.
    await putComics((slug, _) => _local.comicJson(slug) == null);
    for (final MapEntry(key: slug, value: details) in comics.entries) {
      _saved[slug] = (details, _local.comicJson(slug));
    }
    await _journal.recordSaved(
      LibraryKind.history,
      history.map((h) => h.slug),
      quiet: quiet,
    );
    return unit;
  });

  bool _isStored(String slug, ComicDetails details) {
    final (savedDetails, json) = _saved[slug] ?? (null, null);
    return identical(savedDetails, details) &&
        json != null &&
        identical(json, _local.comicJson(slug));
  }

  /// Comic records left without entries are deleted; only the comics of
  /// the removed entries are checked.
  @override
  Future<Either<Failure, Unit>> removeHistory(List<String> slugs) =>
      runLocal(() async {
        final comics = {
          for (final slug in slugs)
            if (_local.getEntry(slug) case final entry?) entry.comicSlug,
        };
        await _local.deleteEntries(slugs);
        await _pruneComics(comics);
        await _journal.recordDeleted(LibraryKind.history, slugs);
        return unit;
      });

  @override
  Future<Either<Failure, Unit>> removeComicHistory(String comicSlug) =>
      removeComicsHistory([comicSlug]);

  /// Finds the entries by key (`<comicSlug>/<number>`), without decoding
  /// the history.
  @override
  Future<Either<Failure, Unit>> removeComicsHistory(List<String> comicSlugs) =>
      runLocal(() async {
        final slugs = _local.entryKeysOf(comicSlugs.toSet());
        await _local.deleteEntries(slugs);
        await _local.deleteComics(comicSlugs);
        comicSlugs.forEach(_saved.remove);
        await _journal.recordDeleted(LibraryKind.history, slugs);
        return unit;
      });

  @override
  Future<Either<Failure, Unit>> clearHistory() => runLocal(() async {
    final slugs = _local.entryKeys();
    await _local.clear();
    _saved.clear();
    await _journal.recordDeleted(LibraryKind.history, slugs);
    return unit;
  });

  /// Drops the records of [comics] that no entry refers to any more.
  Future<void> _pruneComics(Set<String> comics) async {
    if (comics.isEmpty) return;
    final used = _local.comicsWithEntries(comics);
    final unused = [
      for (final slug in comics)
        if (!used.contains(slug)) slug,
    ];
    unused.forEach(_saved.remove);
    if (unused.isNotEmpty) await _local.deleteComics(unused);
  }
}
