import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:bacakomik_app/core/error/failures.dart';
import 'package:bacakomik_app/core/source/comic_key.dart';
import 'package:bacakomik_app/core/storage/hive_boxes.dart';
import 'package:bacakomik_app/core/storage/library_journal.dart';
import 'package:bacakomik_app/core/usecase/usecase.dart';
import 'package:bacakomik_app/core/utils/clock.dart';
import 'package:bacakomik_app/features/bookmark/data/datasources/bookmark_local_data_source.dart';
import 'package:bacakomik_app/features/bookmark/data/repositories/bookmark_repository_impl.dart';
import 'package:bacakomik_app/features/bookmark/domain/entities/bookmark.dart';
import 'package:bacakomik_app/features/category/data/datasources/category_local_data_source.dart';
import 'package:bacakomik_app/features/category/domain/entities/category.dart';
import 'package:bacakomik_app/features/history/data/datasources/history_local_data_source.dart';
import 'package:bacakomik_app/features/history/data/repositories/history_repository_impl.dart';
import 'package:bacakomik_app/features/history/domain/entities/read_history.dart';
import 'package:bacakomik_app/features/sync/data/datasources/drive_data_source.dart';
import 'package:bacakomik_app/features/sync/data/datasources/google_auth_data_source.dart';
import 'package:bacakomik_app/features/sync/data/repositories/sync_repository_impl.dart';
import 'package:bacakomik_app/features/sync/domain/entities/sync_snapshot.dart';
import 'package:bacakomik_app/features/sync/domain/repositories/sync_repository.dart';
import 'package:bacakomik_app/features/sync/domain/usecases/migrate_library.dart';
import 'package:bacakomik_app/features/sync/domain/usecases/sync_usecases.dart';
import 'package:bacakomik_app/features/sync/presentation/bloc/sync_cubit.dart';
import 'package:bacakomik_app/features/sync/presentation/widgets/sync_section.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hive_ce/hive.dart';
import 'package:mocktail/mocktail.dart';

import '../fixtures/library_fixtures.dart';
import '../helpers/hive.dart';

class FixedClock implements Clock {
  FixedClock(this.value);

  DateTime value;

  @override
  DateTime now() => value;
}

class MockSyncRepository extends Mock implements SyncRepository {}

class MockAuth extends Mock implements GoogleAuthDataSource {}

class MockDrive extends Mock implements DriveDataSource {}

class MockSyncLibrary extends Mock implements SyncLibrary {}

class MockMigrateLocal extends Mock implements MigrateLocalLibrary {}

DateTime at(int ms) => DateTime.fromMillisecondsSinceEpoch(ms);

/// Details of a comic of the default source, which MigrateSnapshot leaves
/// alone.
final currentDetails = sampleComicDetails.copyWith(
  source: ComicKey.defaultSource,
);

Bookmark bookmark(String slug, int updated, {String title = 'Solo'}) =>
    Bookmark(
      slug: slug,
      comicDetails: currentDetails.copyWith(title: title),
      updatedDate: at(updated),
    );

ReadHistory read(String slug, int date, {int? page}) => ReadHistory(
  slug: slug,
  chapterNumber: slug.split('/').last,
  readDate: at(date),
  comicDetails: currentDetails,
  comicSlug: slug.split('/').first,
  page: page,
  pageCount: page == null ? null : 20,
);

LibraryCategory category(String id, int date, {String name = 'C'}) =>
    LibraryCategory(id: id, name: name, order: 0, updatedDate: at(date));

ComicCategories inCategories(String slug, List<String> ids, int date) =>
    ComicCategories(slug: slug, categoryIds: ids, updatedDate: at(date));

SyncSnapshot merge(SyncSnapshot a, SyncSnapshot b, {int keepSince = 0}) =>
    SyncSnapshot.merge(a, b, keepDeletionsSince: at(keepSince));

void main() {
  group('SyncSnapshot.merge', () {
    test('keeps entries from both sides', () {
      final merged = merge(
        SyncSnapshot(bookmarks: [bookmark('a', 1)], history: [read('a/1', 1)]),
        SyncSnapshot(bookmarks: [bookmark('b', 1)], history: [read('b/1', 1)]),
      );
      expect(merged.bookmarks.map((b) => b.slug), ['a', 'b']);
      expect(merged.history.map((h) => h.slug), ['a/1', 'b/1']);
    });

    test('newest version of the same slug wins', () {
      final merged = merge(
        SyncSnapshot(
          bookmarks: [bookmark('a', 1, title: 'Old')],
          history: [read('a/1', 5, page: 3)],
        ),
        SyncSnapshot(
          bookmarks: [bookmark('a', 2, title: 'New')],
          history: [read('a/1', 9)],
        ),
      );
      expect(merged.bookmarks.single.comicDetails.title, 'New');
      expect(merged.history.single.isFinished, isTrue);
    });

    test('a deletion removes older entries on the other side', () {
      final merged = merge(
        SyncSnapshot(
          deletedBookmarks: {'a': at(10)},
          deletedHistory: {'a/1': at(10)},
        ),
        SyncSnapshot(bookmarks: [bookmark('a', 5)], history: [read('a/1', 5)]),
      );
      expect(merged.bookmarks, isEmpty);
      expect(merged.history, isEmpty);
      expect(merged.deletedBookmarks, {'a': at(10)});
    });

    test('an entry saved again after its deletion stays, old date and all', () {
      // Deleted at 10 on one device; a backup restored at 20 on another
      // brings it back with its old date (5).
      final restored = merge(
        SyncSnapshot(
          deletedBookmarks: {'a': at(10)},
          deletedHistory: {'a/1': at(10)},
        ),
        SyncSnapshot(
          bookmarks: [bookmark('a', 5)],
          history: [read('a/1', 5)],
          savedBookmarks: {'a': at(20)},
          savedHistory: {'a/1': at(20)},
        ),
      );
      expect(restored.bookmarks.map((b) => b.slug), ['a']);
      expect(restored.history.map((h) => h.slug), ['a/1']);
      expect(restored.deletedBookmarks, isEmpty);
      expect(restored.deletedHistory, isEmpty);
      expect(restored.savedBookmarks, {'a': at(20)});

      // A device that still has the deletion keeps the entry too.
      final elsewhere = merge(
        SyncSnapshot(deletedBookmarks: {'a': at(10)}),
        restored,
      );
      expect(elsewhere.bookmarks.map((b) => b.slug), ['a']);
      expect(elsewhere.deletedBookmarks, isEmpty);

      // Deleting it again later wins.
      final deletedAgain = merge(
        SyncSnapshot(deletedBookmarks: {'a': at(30)}),
        restored,
      );
      expect(deletedAgain.bookmarks, isEmpty);
      expect(deletedAgain.deletedBookmarks, {'a': at(30)});
    });

    test('save times expire with deletions', () {
      final merged = merge(
        SyncSnapshot(savedBookmarks: {'a': at(5), 'b': at(50)}),
        const SyncSnapshot(),
        keepSince: 10,
      );
      expect(merged.savedBookmarks, {'b': at(50)});
    });

    test('an entry saved after the deletion stays', () {
      final merged = merge(
        SyncSnapshot(deletedBookmarks: {'a': at(10)}),
        SyncSnapshot(bookmarks: [bookmark('a', 11)]),
      );
      expect(merged.bookmarks.single.slug, 'a');
    });

    test('keeps the newest deletion and forgets old ones', () {
      final merged = merge(
        SyncSnapshot(deletedHistory: {'a/1': at(50), 'b/1': at(5)}),
        SyncSnapshot(deletedHistory: {'a/1': at(60)}),
        keepSince: 10,
      );
      expect(merged.deletedHistory, {'a/1': at(60)});
    });

    test('categories: newest wins, deletions apply', () {
      final merged = merge(
        SyncSnapshot(
          categories: [
            category('x', 1, name: 'Old'),
            category('y', 1),
          ],
          comicCategories: [
            inCategories('a', ['x'], 1),
          ],
        ),
        SyncSnapshot(
          categories: [category('x', 2, name: 'New')],
          comicCategories: [
            inCategories('a', ['x', 'y'], 2),
          ],
          deletedCategories: {'y': at(2)},
        ),
      );
      expect(merged.categories.single.name, 'New');
      expect(merged.comicCategories.single.categoryIds, ['x', 'y']);
      expect(merged.deletedCategories.keys, ['y']);
    });

    test('a copy from an app without categories keeps them', () {
      final local = SyncSnapshot(
        bookmarks: [bookmark('a', 1)],
        categories: [category('x', 1)],
        comicCategories: [
          inCategories('a', ['x'], 1),
        ],
      );
      final merged = merge(local, SyncSnapshot(bookmarks: [bookmark('a', 5)]));
      expect(merged.categories, local.categories);
      expect(merged.comicCategories, local.comicCategories);
    });

    test('a copy from an app without added dates keeps them', () {
      final merged = merge(
        SyncSnapshot(bookmarks: [bookmark('a', 1).copyWith(addedDate: at(1))]),
        // Refreshed later on an older app version, which drops the date.
        SyncSnapshot(bookmarks: [bookmark('a', 5)]),
      );

      expect(merged.bookmarks.single.updatedDate, at(5));
      expect(merged.bookmarks.single.addedDate, at(1));
    });

    test('sameAs ignores list order', () {
      final a = SyncSnapshot(bookmarks: [bookmark('a', 1), bookmark('b', 1)]);
      final b = SyncSnapshot(bookmarks: [bookmark('b', 1), bookmark('a', 1)]);
      expect(a.sameAs(b), isTrue);
    });
  });

  group('sync file format', () {
    test('round-trips categories', () {
      final snapshot = SyncSnapshot(
        categories: [category('x', 1)],
        comicCategories: [
          inCategories('a', ['x'], 2),
        ],
        deletedCategories: {'y': at(3)},
      );
      expect(
        SyncRepositoryImpl.decode(SyncRepositoryImpl.encode(snapshot)),
        snapshot,
      );
    });

    test('round-trips entries and deletions', () {
      final snapshot = SyncSnapshot(
        bookmarks: [bookmark('solo-leveling', 1)],
        history: [read('solo-leveling/1', 2), read('solo-leveling/2', 3)],
        deletedBookmarks: {'x': at(4)},
        deletedHistory: {'x/1': at(5)},
      ).sorted();
      expect(
        SyncRepositoryImpl.decode(SyncRepositoryImpl.encode(snapshot)),
        snapshot,
      );
    });
  });

  group('sync file', () {
    test('round-trips save times; a file without them reads', () {
      final snapshot = SyncSnapshot(
        bookmarks: [bookmark('a', 1)],
        savedBookmarks: {'a': at(7)},
        savedHistory: {'a/1': at(8)},
        savedCategories: {'c': at(9)},
      ).sorted();
      expect(
        SyncRepositoryImpl.decode(SyncRepositoryImpl.encode(snapshot)),
        snapshot,
      );
      expect(
        SyncRepositoryImpl.decode(
          SyncRepositoryImpl.encode(snapshot.copyWith(savedBookmarks: {})),
        ).savedBookmarks,
        isEmpty,
      );
    });

    test('an unreadable entry is skipped, not the whole file', () {
      final good = SyncRepositoryImpl.encode(
        SyncSnapshot(bookmarks: [bookmark('a', 1)]),
      );
      final json =
          jsonDecode(utf8.decode(gzip.decode(good))) as Map<String, dynamic>;
      (json['bookmarks'] as List).add({'slug': 'broken'});
      json['deletedBookmarks'] = {'x': 'not a time', 'y': 4};
      final decoded = SyncRepositoryImpl.decode(
        Uint8List.fromList(gzip.encode(utf8.encode(jsonEncode(json)))),
      );
      expect(decoded.bookmarks.map((b) => b.slug), ['a']);
      expect(decoded.deletedBookmarks, {'y': at(4)});
    });
  });

  group('Drive errors', () {
    DioException error(int status, [Object? body]) => DioException(
      requestOptions: RequestOptions(),
      response: Response(
        requestOptions: RequestOptions(),
        statusCode: status,
        data: body,
      ),
    );
    Map<String, Object> reason(String reason) => {
      'error': {
        'code': 403,
        'errors': [
          {'domain': 'global', 'reason': reason},
        ],
      },
    };

    test('only lost access is a sign-out', () {
      expect(SyncRepositoryImpl.driveFailure(error(401)), isA<AuthFailure>());
      expect(
        SyncRepositoryImpl.driveFailure(
          error(403, reason('insufficientPermissions')),
        ),
        isA<AuthFailure>(),
      );
      // Bytes, as a download's error body comes.
      expect(
        SyncRepositoryImpl.driveFailure(
          error(403, utf8.encode(jsonEncode(reason('authError')))),
        ),
        isA<AuthFailure>(),
      );
      for (final quota in [
        'userRateLimitExceeded',
        'rateLimitExceeded',
        'storageQuotaExceeded',
      ]) {
        expect(
          SyncRepositoryImpl.driveFailure(error(403, reason(quota))),
          isA<ServerFailure>(),
        );
      }
      expect(
        SyncRepositoryImpl.driveFailure(error(403, 'Forbidden')),
        isA<ServerFailure>(),
      );
      expect(
        SyncRepositoryImpl.driveFailure(
          DioException(requestOptions: RequestOptions()),
        ),
        isA<NetworkFailure>(),
      );
    });
  });

  group('local library', () {
    late Future<void> Function() tearDownHive;
    late FixedClock clock;
    late LibraryJournal journal;
    late BookmarkRepositoryImpl bookmarks;
    late HistoryRepositoryImpl history;
    late SyncRepositoryImpl sync;

    setUp(() async {
      tearDownHive = await setUpTempHive();
      clock = FixedClock(at(1000));
      journal = LibraryJournal(
        await Hive.openBox<String>(HiveBoxes.libraryDeletions),
        clock,
      );
      final bookmarkSource = BookmarkLocalDataSourceImpl(
        await Hive.openBox<String>(HiveBoxes.bookmarks),
      );
      final historySource = HistoryLocalDataSourceImpl(
        await Hive.openBox<String>(HiveBoxes.historyEntries),
        await Hive.openBox<String>(HiveBoxes.historyComics),
      );
      bookmarks = BookmarkRepositoryImpl(bookmarkSource, journal);
      history = HistoryRepositoryImpl(historySource, journal);
      sync = SyncRepositoryImpl(
        MockAuth(),
        MockDrive(),
        bookmarkSource,
        historySource,
        CategoryLocalDataSourceImpl(
          await Hive.openBox<String>(HiveBoxes.categories),
          await Hive.openBox<String>(HiveBoxes.comicCategories),
        ),
        journal,
        await Hive.openBox<String>(HiveBoxes.sync),
      );
    });

    tearDown(() => tearDownHive());

    test('deletes are journaled, saves clear them', () async {
      await bookmarks.saveBookmarks([bookmark('a', 1)]);
      await history.saveHistory([read('c/1', 1), read('c/2', 2)]);

      await bookmarks.removeBookmarks(['a']);
      await history.clearHistory();
      expect(journal.deleted(LibraryKind.bookmark), {'a': at(1000)});
      expect(journal.deleted(LibraryKind.history).keys, {'c/1', 'c/2'});

      await bookmarks.saveBookmarks([bookmark('a', 2000)]);
      expect(journal.deleted(LibraryKind.bookmark), isEmpty);
    });

    test('library edits fire changes', () async {
      var events = 0;
      journal.changes.listen((_) => events++);
      await bookmarks.saveBookmarks([bookmark('a', 1)]);
      await history.removeHistory(['c/1']);
      expect(events, 2);
    });

    test('writeLocal replaces the library without firing changes', () async {
      await bookmarks.saveBookmarks([bookmark('old', 1)]);
      await history.saveHistory([read('old/1', 1)]);
      var events = 0;
      journal.changes.listen((_) => events++);

      final snapshot = SyncSnapshot(
        bookmarks: [bookmark('new', 2)],
        history: [read('new/1', 2)],
        deletedBookmarks: {'old': at(3)},
      );
      await sync.writeLocal(snapshot);

      expect(
        (await sync.readLocal()).getOrElse((_) => throw StateError('')),
        snapshot.sorted(),
      );
      expect(events, 0);
    });

    test('saving a deleted entry again records when', () async {
      await bookmarks.saveBookmarks([bookmark('a', 1)]);
      await bookmarks.saveBookmarks([bookmark('b', 1)]);
      expect(journal.saved(LibraryKind.bookmark), isEmpty);

      await bookmarks.removeBookmarks(['a']);
      clock.value = at(2000);
      // A restore brings back its old date.
      await bookmarks.saveBookmarks([bookmark('a', 1), bookmark('b', 1)]);

      expect(journal.deleted(LibraryKind.bookmark), isEmpty);
      expect(journal.saved(LibraryKind.bookmark), {'a': at(2000)});
      final local = (await sync.readLocal()).getOrElse((f) => fail('$f'));
      expect(local.savedBookmarks, {'a': at(2000)});

      // The deletion synced from elsewhere no longer drops it.
      final merged = merge(
        local,
        SyncSnapshot(deletedBookmarks: {'a': at(1000)}),
      );
      expect(merged.bookmarks.map((b) => b.slug), ['a', 'b']);
    });

    test('writeLocal keeps edits made after the library was read', () async {
      await bookmarks.saveBookmarks([bookmark('a', 1), bookmark('gone', 1)]);
      final local = (await sync.readLocal()).getOrElse((f) => fail('$f'));

      // Edits while the sync downloads and merges.
      await bookmarks.saveBookmarks([
        bookmark('a', 5, title: 'Edited'),
        bookmark('new', 5),
      ]);
      await bookmarks.removeBookmarks(['gone']);
      await bookmarks.saveBookmarks([bookmark('gone', 6)]);

      // The merge, from the earlier read, drops gone and changes a.
      await sync.writeLocal(
        local.copyWith(
          bookmarks: [bookmark('a', 3, title: 'Remote')],
          deletedBookmarks: {'gone': at(2)},
        ),
      );

      final now = (await sync.readLocal()).getOrElse((f) => fail('$f'));
      expect(
        {for (final b in now.bookmarks) b.slug: b.comicDetails.title},
        {'a': 'Edited', 'new': 'Solo', 'gone': 'Solo'},
      );
      // The next sync keeps what was saved meanwhile.
      expect(merge(now, const SyncSnapshot()).bookmarks.map((b) => b.slug), [
        'a',
        'gone',
        'new',
      ]);
    });

    test('writeLocal still applies records unchanged since the read', () async {
      await bookmarks.saveBookmarks([bookmark('a', 1), bookmark('b', 1)]);
      await sync.readLocal();

      await sync.writeLocal(
        SyncSnapshot(
          bookmarks: [bookmark('a', 3, title: 'Remote')],
          deletedBookmarks: {'b': at(2)},
        ),
      );

      final now = (await sync.readLocal()).getOrElse((f) => fail('$f'));
      expect(now.bookmarks.single.comicDetails.title, 'Remote');
      expect(now.deletedBookmarks, {'b': at(2)});
    });
  });

  group('SyncCubit', () {
    late MockSyncRepository repo;
    late MockSyncLibrary syncLibrary;
    late MockMigrateLocal migrateLocal;
    late Future<void> Function() tearDownHive;
    late SyncCubit cubit;

    setUpAll(TestWidgetsFlutterBinding.ensureInitialized);

    setUp(() async {
      tearDownHive = await setUpTempHive();
      repo = MockSyncRepository();
      syncLibrary = MockSyncLibrary();
      migrateLocal = MockMigrateLocal();
      when(() => repo.storedAccount()).thenReturn('me@example.com');
      when(() => repo.lastSyncedAt()).thenReturn(at(5));
      when(() => migrateLocal(const NoParams()))
          .thenAnswer((_) async => right(false));
      cubit = SyncCubit(
        RestoreSyncAccount(repo),
        SignInSync(repo),
        SignOutSync(repo),
        syncLibrary,
        migrateLocal,
        LibraryJournal(
          await Hive.openBox<String>(HiveBoxes.libraryDeletions),
          FixedClock(at(1)),
        ),
      );
    });

    tearDown(() async {
      await cubit.close();
      await tearDownHive();
    });

    test('a failed restore at start keeps the account and retries', () async {
      when(() => repo.restoreAccount())
          .thenAnswer((_) async => left(const ServerFailure('offline')));

      await cubit.start();

      expect(cubit.state.email, 'me@example.com');
      expect(cubit.state.status, SyncStatus.failed);
      verifyNever(() => syncLibrary(const NoParams()));

      when(() => repo.restoreAccount())
          .thenAnswer((_) async => right('me@example.com'));
      when(
        () => syncLibrary(const NoParams()),
      ).thenAnswer((_) async => right((syncedAt: at(9), localChanged: false)));
      await cubit.sync();

      expect(cubit.state.status, SyncStatus.idle);
      expect(cubit.state.lastSyncedAt, at(9));
    });

    test('an error thrown while syncing does not leave it syncing', () async {
      when(() => repo.restoreAccount())
          .thenAnswer((_) async => right('me@example.com'));
      when(() => syncLibrary(const NoParams())).thenThrow(StateError('bug'));

      await cubit.start();

      expect(cubit.state.status, SyncStatus.failed);
      expect(cubit.state.email, 'me@example.com');
    });

    test('lost access signs out', () async {
      when(() => repo.restoreAccount())
          .thenAnswer((_) async => right('me@example.com'));
      when(() => syncLibrary(const NoParams()))
          .thenAnswer((_) async => left(const AuthFailure('revoked')));

      await cubit.start();

      expect(cubit.state.email, isNull);
      expect(cubit.state.status, SyncStatus.failed);
    });
  });

  group('SyncLibrary', () {
    late MockSyncRepository repo;
    late SyncLibrary syncLibrary;
    final now = at(1000);

    setUpAll(() {
      registerFallbackValue(const SyncSnapshot());
    });

    setUp(() {
      repo = MockSyncRepository();
      final clock = FixedClock(now);
      syncLibrary = SyncLibrary(repo, MigrateSnapshot(clock), clock);
      when(() => repo.writeLocal(any())).thenAnswer((_) async => right(unit));
      when(() => repo.upload(any())).thenAnswer((_) async => right(unit));
      when(() => repo.saveLastSyncedAt(any())).thenAnswer((_) async {});
    });

    test('first sync uploads the local library', () async {
      final local = SyncSnapshot(bookmarks: [bookmark('a', 1)]);
      when(() => repo.download()).thenAnswer((_) async => right(null));
      when(() => repo.readLocal()).thenAnswer((_) async => right(local));

      final result = await syncLibrary(const NoParams());

      expect(result, right((syncedAt: now, localChanged: false)));
      verify(() => repo.upload(local)).called(1);
      verifyNever(() => repo.writeLocal(any()));
      verify(() => repo.saveLastSyncedAt(now)).called(1);
    });

    test('pulls remote entries and skips an unchanged upload', () async {
      final remote = SyncSnapshot(bookmarks: [bookmark('a', 1)]);
      when(() => repo.download()).thenAnswer((_) async => right(remote));
      when(() => repo.readLocal())
          .thenAnswer((_) async => right(const SyncSnapshot()));

      final result = await syncLibrary(const NoParams());

      expect(result, right((syncedAt: now, localChanged: true)));
      verify(() => repo.writeLocal(remote)).called(1);
      verifyNever(() => repo.upload(any()));
    });

    test('moves comics stored before sources to the legacy source', () async {
      final local = SyncSnapshot(
        bookmarks: [
          Bookmark(
            slug: 'solo',
            comicDetails: sampleComicDetails,
            updatedDate: at(1),
          ),
        ],
      );
      when(() => repo.download()).thenAnswer((_) async => right(null));
      // Re-read after migrating still returns the old entry.
      when(() => repo.readLocal()).thenAnswer((_) async => right(local));

      final result = await syncLibrary(const NoParams());

      expect(result, right((syncedAt: now, localChanged: true)));
      final written =
          verify(() => repo.writeLocal(captureAny())).captured.single
              as SyncSnapshot;
      expect(written.bookmarks.single.slug, 'voratoon:solo');
      expect(written.deletedBookmarks, {'solo': now});
      verify(() => repo.upload(written)).called(1);
    });

    test('download failure stops before writing', () async {
      when(() => repo.download())
          .thenAnswer((_) async => left(const NetworkFailure()));
      when(() => repo.readLocal())
          .thenAnswer((_) async => right(const SyncSnapshot()));

      final result = await syncLibrary(const NoParams());

      expect(result.isLeft(), isTrue);
      verifyNever(() => repo.writeLocal(any()));
      verifyNever(() => repo.upload(any()));
      verifyNever(() => repo.saveLastSyncedAt(any()));
    });
  });

  test('formatSyncTime shows the date only for other days', () {
    final now = DateTime(2026, 10, 21, 20);
    expect(formatSyncTime(DateTime(2026, 10, 21, 9, 5), now: now), '09:05');
    expect(
      formatSyncTime(DateTime(2026, 10, 20, 14, 30), now: now),
      '20/10 14:30',
    );
  });
}
