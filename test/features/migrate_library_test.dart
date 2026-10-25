import 'package:bacakomik_app/core/data/models/comic_details_model.dart';
import 'package:bacakomik_app/core/domain/entities/comic_details.dart';
import 'package:bacakomik_app/core/error/failures.dart';
import 'package:bacakomik_app/core/source/comic_key.dart';
import 'package:bacakomik_app/core/usecase/usecase.dart';
import 'package:bacakomik_app/core/utils/clock.dart';
import 'package:bacakomik_app/features/bookmark/domain/entities/bookmark.dart';
import 'package:bacakomik_app/features/history/domain/entities/read_history.dart';
import 'package:bacakomik_app/features/sync/domain/entities/sync_snapshot.dart';
import 'package:bacakomik_app/features/sync/domain/repositories/sync_repository.dart';
import 'package:bacakomik_app/features/sync/domain/usecases/migrate_library.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../fixtures/library_fixtures.dart';

class FixedClock implements Clock {
  FixedClock(this.value);

  final DateTime value;

  @override
  DateTime now() => value;
}

class MockSyncRepository extends Mock implements SyncRepository {}

DateTime at(int ms) => DateTime.fromMillisecondsSinceEpoch(ms);

final now = at(1000);
final keepSince = at(0);

/// Comic stored before the app had sources: no source, bare slugs.
const legacy = sampleComicDetails;

final marked = sampleComicDetails.copyWith(source: ComicSource.legacy);

final current = sampleComicDetails.copyWith(source: ComicKey.defaultSource);

/// [sampleComicDetails] as moved to the legacy source.
final moved = sampleComicDetails.copyWith(
  source: ComicSource.legacy,
  chapters: const [
    Chapter(number: '2', slug: 'voratoon:solo-leveling/2', date: '-'),
    Chapter(number: '1', slug: 'voratoon:solo-leveling/1', date: '-'),
  ],
);

Bookmark bookmark(String slug, int updated, {ComicDetails details = legacy}) =>
    Bookmark(slug: slug, comicDetails: details, updatedDate: at(updated));

ReadHistory read(
  String slug,
  int date, {
  ComicDetails details = legacy,
  int? page,
}) {
  final separator = slug.lastIndexOf('/');
  return ReadHistory(
    slug: slug,
    chapterNumber: slug.substring(separator + 1),
    readDate: at(date),
    comicDetails: details,
    comicSlug: slug.substring(0, separator),
    page: page,
    pageCount: page == null ? null : 20,
  );
}

void main() {
  group('MigrateSnapshot', () {
    final migrate = MigrateSnapshot(FixedClock(now));

    Future<SyncSnapshot> run(SyncSnapshot s) =>
        migrate(s, keepDeletionsSince: keepSince);

    test('moves comics without a source and keeps read progress', () async {
      final result = await run(
        SyncSnapshot(
          bookmarks: [bookmark('solo-leveling', 5)],
          history: [read('solo-leveling/1', 7, page: 3)],
        ),
      );

      final b = result.bookmarks.single;
      expect(b.slug, 'voratoon:solo-leveling');
      expect(b.comicDetails, moved);
      expect(b.updatedDate, at(5));
      final h = result.history.single;
      expect(h.slug, 'voratoon:solo-leveling/1');
      expect(h.comicSlug, 'voratoon:solo-leveling');
      expect(h.chapterNumber, '1');
      expect(h.comicDetails, moved);
      expect((h.readDate, h.page, h.pageCount), (at(7), 3, 20));
    });

    test('records deletions of the old keys at now', () async {
      final result = await run(
        SyncSnapshot(
          bookmarks: [bookmark('solo-leveling', 5)],
          history: [read('solo-leveling/1', 7), read('solo-leveling/2', 8)],
          deletedBookmarks: {'other': at(3)},
        ),
      );

      expect(result.deletedBookmarks, {'other': at(3), 'solo-leveling': now});
      expect(result.deletedHistory, {
        'solo-leveling/1': now,
        'solo-leveling/2': now,
      });
    });

    test('moves comics marked with the legacy source', () async {
      final result = await run(
        SyncSnapshot(
          bookmarks: [bookmark('solo-leveling', 5, details: marked)],
          history: [read('solo-leveling/2', 7, details: marked)],
        ),
      );

      expect(result.bookmarks.single.slug, 'voratoon:solo-leveling');
      expect(result.bookmarks.single.comicDetails, moved);
      expect(result.history.single.slug, 'voratoon:solo-leveling/2');
    });

    test(
      'leaves comics of the default source and prefixed keys alone',
      () async {
        final snapshot = SyncSnapshot(
          bookmarks: [
            bookmark('solo-leveling', 5, details: current),
            bookmark('voratoon:other', 6, details: moved),
            // A prefixed key is never moved, whatever its details say.
            bookmark('voratoon:third', 6),
          ],
          history: [read('solo-leveling/1', 7, details: current)],
        );

        expect(await run(snapshot), snapshot);
      },
    );

    test('moves only the legacy entries of a mixed library', () async {
      final result = await run(
        SyncSnapshot(
          bookmarks: [
            bookmark('solo-leveling', 5),
            bookmark('kept', 6, details: current),
          ],
        ),
      );

      expect(
        result.bookmarks.map((b) => b.slug),
        unorderedEquals(['voratoon:solo-leveling', 'kept']),
      );
      expect(result.deletedBookmarks.keys, ['solo-leveling']);
    });

    test('a second run changes nothing', () async {
      final once = await run(
        SyncSnapshot(
          bookmarks: [bookmark('solo-leveling', 5)],
          history: [read('solo-leveling/1', 7)],
        ),
      );

      final twice = await run(once);

      expect(twice.sameAs(once), isTrue);
    });

    test('keeps the newest when the new key is already bookmarked', () async {
      final result = await run(
        SyncSnapshot(
          bookmarks: [
            bookmark('solo-leveling', 9),
            bookmark('voratoon:solo-leveling', 2, details: moved),
          ],
        ),
      );

      expect(result.bookmarks.single.slug, 'voratoon:solo-leveling');
      expect(result.bookmarks.single.updatedDate, at(9));
    });

    test('a not yet migrated copy from another device is dropped', () async {
      final migrated = await run(
        SyncSnapshot(bookmarks: [bookmark('solo-leveling', 5)]),
      );

      final merged = SyncSnapshot.merge(
        migrated,
        SyncSnapshot(bookmarks: [bookmark('solo-leveling', 5)]),
        keepDeletionsSince: keepSince,
      );

      expect(merged.bookmarks.single.slug, 'voratoon:solo-leveling');
    });
  });

  group('MigrateLocalLibrary', () {
    late MockSyncRepository repo;
    late MigrateLocalLibrary useCase;

    setUpAll(() {
      registerFallbackValue(const SyncSnapshot());
      registerFallbackValue((String _) => false);
      registerFallbackValue((String _, ComicDetails _) => false);
    });

    void storedComicsLegacy(bool legacy) => when(
      () => repo.anyLocalComic(
        where: any(named: 'where'),
        test: any(named: 'test'),
      ),
    ).thenAnswer((_) async => right(legacy));

    setUp(() {
      repo = MockSyncRepository();
      final clock = FixedClock(now);
      useCase = MigrateLocalLibrary(repo, MigrateSnapshot(clock), clock);
      when(() => repo.writeLocal(any())).thenAnswer((_) async => right(unit));
      storedComicsLegacy(true);
    });

    test('without a legacy comic the library is not read', () async {
      storedComicsLegacy(false);

      expect(await useCase(const NoParams()), right(false));
      verifyNever(() => repo.readLocal());
      verifyNever(() => repo.writeLocal(any()));
      final [where as bool Function(String), test as Function] = verify(
        () => repo.anyLocalComic(
          where: captureAny(named: 'where'),
          test: captureAny(named: 'test'),
        ),
      ).captured;
      // Only default-source keys are worth decoding.
      expect(where('solo-leveling'), isTrue);
      expect(where('voratoon:solo-leveling'), isFalse);
      expect(test('solo-leveling', legacy), isTrue);
      expect(test('solo-leveling', current), isFalse);
      expect(test('voratoon:solo-leveling', legacy), isFalse);
    });

    test('writes only when something changed', () async {
      final local = SyncSnapshot(bookmarks: [bookmark('solo-leveling', 5)]);
      when(() => repo.readLocal()).thenAnswer((_) async => right(local));

      expect(await useCase(const NoParams()), right(true));
      final written =
          verify(() => repo.writeLocal(captureAny())).captured.single
              as SyncSnapshot;
      expect(written.bookmarks.single.slug, 'voratoon:solo-leveling');

      when(() => repo.readLocal()).thenAnswer((_) async => right(written));
      expect(await useCase(const NoParams()), right(false));
      verifyNever(() => repo.writeLocal(any()));
    });

    test('a library of the default source is not written', () async {
      when(() => repo.readLocal()).thenAnswer(
        (_) async => right(
          SyncSnapshot(
            bookmarks: [bookmark('solo-leveling', 5, details: current)],
          ),
        ),
      );

      expect(await useCase(const NoParams()), right(false));
      verifyNever(() => repo.writeLocal(any()));
    });

    test('read failure is returned', () async {
      when(() => repo.readLocal())
          .thenAnswer((_) async => left(const CacheFailure('broken')));

      expect(
        await useCase(const NoParams()),
        left(const CacheFailure('broken')),
      );
      verifyNever(() => repo.writeLocal(any()));
    });
  });

  test('stored details keep source, and old data reads as null', () {
    final json = ComicDetailsModel.fromEntity(moved).toJson();
    expect(json['source'], ComicSource.legacy);
    expect(ComicDetailsModel.fromJson(json).toEntity(), moved);

    final old = ComicDetailsModel.fromEntity(sampleComicDetails).toJson();
    expect(old.containsKey('source'), isFalse);
    expect(ComicDetailsModel.fromJson(old).toEntity().source, isNull);
  });
}
