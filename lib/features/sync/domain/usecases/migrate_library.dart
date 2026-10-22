import 'package:bacakomik_app/core/domain/entities/comic_details.dart';
import 'package:bacakomik_app/core/error/failures.dart';
import 'package:bacakomik_app/core/usecase/usecase.dart';
import 'package:bacakomik_app/core/utils/clock.dart';
import 'package:bacakomik_app/features/sync/domain/entities/sync_snapshot.dart';
import 'package:bacakomik_app/features/sync/domain/repositories/series_lookup_repository.dart';
import 'package:bacakomik_app/features/sync/domain/repositories/sync_repository.dart';
import 'package:bacakomik_app/features/sync/domain/usecases/sync_usecases.dart';
import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

/// Moves bookmarks and history stored before the API switched source
/// ([ComicDetails.source] is null) to the current source: new slug, fresh
/// details. Read progress (chapter numbers, pages, dates) is kept.
///
/// A comic whose slug changed leaves deletions for its old slugs, so copies
/// from devices that were not migrated yet are dropped by the sync merge. A
/// comic that is not in the current source is kept and marked
/// [ComicSource.legacy].
@injectable
class MigrateSnapshot {
  const MigrateSnapshot(this._lookup, this._clock);

  /// Each comic costs up to four API requests; the rest are migrated on a
  /// later run, which keeps a large library under the API rate limit.
  static const maxComicsPerRun = 20;

  final SeriesLookupRepository _lookup;
  final Clock _clock;

  Future<SyncSnapshot> call(
    SyncSnapshot snapshot, {
    required DateTime keepDeletionsSince,
  }) async {
    // Taken before the lookups: an entry read meanwhile is newer than the
    // deletion of its old slug, so it survives and is migrated next run.
    final now = _clock.now();

    // Bookmarks first, then the most recently read.
    final pending = <String, ComicDetails>{
      for (final b in snapshot.bookmarks)
        if (b.comicDetails.source == null) b.slug: b.comicDetails,
    };
    final history = [...snapshot.history]
      ..sort((a, b) => b.readDate.compareTo(a.readDate));
    for (final h in history) {
      if (h.comicDetails.source == null) {
        pending.putIfAbsent(h.comicSlug, () => h.comicDetails);
      }
    }
    if (pending.isEmpty) return snapshot;

    final found = <String, SeriesMatch>{};
    for (final MapEntry(key: slug, value: stored) in pending.entries.take(
      maxComicsPerRun,
    )) {
      final result = await _lookup.find(slug, stored);
      // Offline or rate limited: the rest would fail too.
      if (result case Left(value: final failure)) {
        debugPrint('MigrateSnapshot: $failure');
        break;
      }
      final match = result.getOrElse((_) => null);
      found[slug] =
          match ??
          (slug: slug, details: stored.copyWith(source: ComicSource.legacy));
    }
    if (found.isEmpty) return snapshot;

    final deletedBookmarks = {...snapshot.deletedBookmarks};
    final deletedHistory = {...snapshot.deletedHistory};
    final bookmarks = [
      for (final b in snapshot.bookmarks)
        if (found[b.slug] case final match? when b.comicDetails.source == null)
          b.copyWith(slug: match.slug, comicDetails: match.details)
        else
          b,
    ];
    for (final b in snapshot.bookmarks) {
      final match = found[b.slug];
      if (match != null && match.slug != b.slug) deletedBookmarks[b.slug] = now;
    }
    final migratedHistory = [
      for (final h in snapshot.history)
        if (found[h.comicSlug] case final match?
            when h.comicDetails.source == null)
          h.copyWith(
            slug: '${match.slug}/${h.chapterNumber}',
            comicSlug: match.slug,
            comicDetails: match.details,
          )
        else
          h,
    ];
    for (final h in snapshot.history) {
      final match = found[h.comicSlug];
      if (match != null && match.slug != h.comicSlug) {
        deletedHistory[h.slug] = now;
      }
    }

    // The new slug may already be in the library: keep the newest of each.
    return SyncSnapshot.merge(
      snapshot.copyWith(
        bookmarks: bookmarks,
        history: migratedHistory,
        deletedBookmarks: deletedBookmarks,
        deletedHistory: deletedHistory,
      ),
      const SyncSnapshot(),
      keepDeletionsSince: keepDeletionsSince,
    );
  }
}

/// Runs [MigrateSnapshot] on this device's library, for when sync is off.
/// Returns whether the library changed.
@injectable
class MigrateLocalLibrary implements UseCase<bool, NoParams> {
  const MigrateLocalLibrary(this._repository, this._migrate, this._clock);

  final SyncRepository _repository;
  final MigrateSnapshot _migrate;
  final Clock _clock;

  @override
  Future<Either<Failure, bool>> call(NoParams params) async {
    final keepSince = _clock.now().subtract(SyncLibrary.keepDeletionsFor);
    final local = await _repository.readLocal();
    return local.fold((failure) async => left(failure), (local) async {
      var migrated = await _migrate(local, keepDeletionsSince: keepSince);
      if (migrated.sameAs(local)) return right(false);

      // Re-read so edits made during the lookups are kept.
      final latest = await _repository.readLocal();
      if (latest case Right(value: final current)) {
        migrated = SyncSnapshot.merge(
          migrated,
          current,
          keepDeletionsSince: keepSince,
        );
      }
      final written = await _repository.writeLocal(migrated);
      return written.map((_) => true);
    });
  }
}
