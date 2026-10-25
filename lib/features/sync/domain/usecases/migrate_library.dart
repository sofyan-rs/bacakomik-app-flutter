import 'package:bacakomik_app/core/domain/entities/comic_details.dart';
import 'package:bacakomik_app/core/error/failures.dart';
import 'package:bacakomik_app/core/source/comic_key.dart';
import 'package:bacakomik_app/core/usecase/usecase.dart';
import 'package:bacakomik_app/core/utils/clock.dart';
import 'package:bacakomik_app/features/sync/domain/entities/sync_snapshot.dart';
import 'package:bacakomik_app/features/sync/domain/repositories/sync_repository.dart';
import 'package:bacakomik_app/features/sync/domain/usecases/sync_usecases.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

/// Moves bookmarks and history of [ComicSource.legacy] to that source's
/// keys: comics stored before the API switched source (no
/// [ComicDetails.source]) and those an older migration marked legacy still
/// use its bare slugs, which now mean the default source. Read progress is
/// kept as is; no request is made.
///
/// Each moved comic leaves deletions for its old keys, so copies from
/// devices that were not migrated yet are dropped by the sync merge.
@injectable
class MigrateSnapshot {
  const MigrateSnapshot(this._clock);

  final Clock _clock;

  /// Whether a comic stored under [key] could be legacy: only keys of the
  /// default source can be ([isLegacy] also needs its details).
  static bool isLegacyKey(String key) =>
      ComicKey.sourceOf(key) == ComicKey.defaultSource;

  /// Whether the comic stored under [key] with [details] is moved.
  static bool isLegacy(String key, ComicDetails details) =>
      isLegacyKey(key) &&
      (details.source == null || details.source == ComicSource.legacy);

  static String _legacyKey(String slug) =>
      ComicKey.of(ComicSource.legacy, slug);

  static ComicDetails _legacyDetails(String slug, ComicDetails details) =>
      details.copyWith(
        source: ComicSource.legacy,
        chapters: [
          for (final c in details.chapters)
            c.copyWith(slug: '${_legacyKey(slug)}/${c.number}'),
        ],
      );

  Future<SyncSnapshot> call(
    SyncSnapshot snapshot, {
    required DateTime keepDeletionsSince,
  }) async {
    final legacyBookmarks = snapshot.bookmarks.where(
      (b) => isLegacy(b.slug, b.comicDetails),
    );
    final legacyHistory = snapshot.history.where(
      (h) => isLegacy(h.comicSlug, h.comicDetails),
    );
    if (legacyBookmarks.isEmpty && legacyHistory.isEmpty) return snapshot;

    final now = _clock.now();
    final migrated = snapshot.copyWith(
      bookmarks: [
        for (final b in snapshot.bookmarks)
          if (isLegacy(b.slug, b.comicDetails))
            b.copyWith(
              slug: _legacyKey(b.slug),
              comicDetails: _legacyDetails(b.slug, b.comicDetails),
            )
          else
            b,
      ],
      history: [
        for (final h in snapshot.history)
          if (isLegacy(h.comicSlug, h.comicDetails))
            h.copyWith(
              slug: '${_legacyKey(h.comicSlug)}/${h.chapterNumber}',
              comicSlug: _legacyKey(h.comicSlug),
              comicDetails: _legacyDetails(h.comicSlug, h.comicDetails),
            )
          else
            h,
      ],
      deletedBookmarks: {
        ...snapshot.deletedBookmarks,
        for (final b in legacyBookmarks) b.slug: now,
      },
      deletedHistory: {
        ...snapshot.deletedHistory,
        for (final h in legacyHistory) h.slug: now,
      },
    );

    // The new key may already be in the library: keep the newest of each.
    return SyncSnapshot.merge(
      migrated,
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

  /// Runs on every start and resume while signed out, so it first checks
  /// the stored keys: only default-source comics are decoded, and without a
  /// legacy one the library is not read at all.
  @override
  Future<Either<Failure, bool>> call(NoParams params) async {
    final legacy = await _repository.anyLocalComic(
      where: MigrateSnapshot.isLegacyKey,
      test: MigrateSnapshot.isLegacy,
    );
    if (legacy case Left(value: final failure)) return left(failure);
    if (!legacy.getOrElse((_) => true)) return right(false);
    final keepSince = _clock.now().subtract(SyncLibrary.keepDeletionsFor);
    final local = await _repository.readLocal();
    return local.fold((failure) async => left(failure), (local) async {
      final migrated = await _migrate(local, keepDeletionsSince: keepSince);
      if (migrated.sameAs(local)) return right(false);
      final written = await _repository.writeLocal(migrated);
      return written.map((_) => true);
    });
  }
}
