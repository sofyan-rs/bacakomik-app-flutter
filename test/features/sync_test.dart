import 'package:bacakomik_app/core/error/failures.dart';
import 'package:bacakomik_app/core/storage/hive_boxes.dart';
import 'package:bacakomik_app/core/storage/library_journal.dart';
import 'package:bacakomik_app/core/usecase/usecase.dart';
import 'package:bacakomik_app/core/utils/clock.dart';
import 'package:bacakomik_app/features/bookmark/data/datasources/bookmark_local_data_source.dart';
import 'package:bacakomik_app/features/bookmark/data/repositories/bookmark_repository_impl.dart';
import 'package:bacakomik_app/features/bookmark/domain/entities/bookmark.dart';
import 'package:bacakomik_app/features/history/data/datasources/history_local_data_source.dart';
import 'package:bacakomik_app/features/history/data/repositories/history_repository_impl.dart';
import 'package:bacakomik_app/features/history/domain/entities/read_history.dart';
import 'package:bacakomik_app/features/sync/data/datasources/drive_data_source.dart';
import 'package:bacakomik_app/features/sync/data/datasources/google_auth_data_source.dart';
import 'package:bacakomik_app/features/sync/data/repositories/sync_repository_impl.dart';
import 'package:bacakomik_app/features/sync/domain/entities/sync_snapshot.dart';
import 'package:bacakomik_app/features/sync/domain/repositories/series_lookup_repository.dart';
import 'package:bacakomik_app/features/sync/domain/repositories/sync_repository.dart';
import 'package:bacakomik_app/features/sync/domain/usecases/migrate_library.dart';
import 'package:bacakomik_app/features/sync/domain/usecases/sync_usecases.dart';
import 'package:bacakomik_app/features/sync/presentation/widgets/sync_section.dart';
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

class MockLookup extends Mock implements SeriesLookupRepository {}

class MockAuth extends Mock implements GoogleAuthDataSource {}

class MockDrive extends Mock implements DriveDataSource {}

DateTime at(int ms) => DateTime.fromMillisecondsSinceEpoch(ms);

Bookmark bookmark(String slug, int updated, {String title = 'Solo'}) =>
    Bookmark(
      slug: slug,
      comicDetails: sampleComicDetails.copyWith(title: title),
      updatedDate: at(updated),
    );

ReadHistory read(String slug, int date, {int? page}) => ReadHistory(
  slug: slug,
  chapterNumber: slug.split('/').last,
  readDate: at(date),
  comicDetails: sampleComicDetails,
  comicSlug: slug.split('/').first,
  page: page,
  pageCount: page == null ? null : 20,
);

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

    test('sameAs ignores list order', () {
      final a = SyncSnapshot(bookmarks: [bookmark('a', 1), bookmark('b', 1)]);
      final b = SyncSnapshot(bookmarks: [bookmark('b', 1), bookmark('a', 1)]);
      expect(a.sameAs(b), isTrue);
    });
  });

  group('sync file format', () {
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
  });

  group('SyncLibrary', () {
    late MockSyncRepository repo;
    late SyncLibrary syncLibrary;
    final now = at(1000);

    setUpAll(() {
      registerFallbackValue(const SyncSnapshot());
      registerFallbackValue(sampleComicDetails);
    });

    setUp(() {
      repo = MockSyncRepository();
      // The sample comics have no source; offline lookups leave them as-is.
      final lookup = MockLookup();
      when(() => lookup.find(any(), any()))
          .thenAnswer((_) async => left(const NetworkFailure()));
      final clock = FixedClock(now);
      syncLibrary = SyncLibrary(repo, MigrateSnapshot(lookup, clock), clock);
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
