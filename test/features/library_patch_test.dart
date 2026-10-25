import 'package:bacakomik_app/core/domain/entities/comic_details.dart';
import 'package:bacakomik_app/core/storage/hive_boxes.dart';
import 'package:bacakomik_app/core/storage/library_journal.dart';
import 'package:bacakomik_app/features/bookmark/data/datasources/bookmark_local_data_source.dart';
import 'package:bacakomik_app/features/bookmark/data/repositories/bookmark_repository_impl.dart';
import 'package:bacakomik_app/features/bookmark/domain/entities/bookmark.dart';
import 'package:bacakomik_app/features/bookmark/domain/usecases/bookmark_usecases.dart';
import 'package:bacakomik_app/features/bookmark/domain/usecases/migrate_comic.dart';
import 'package:bacakomik_app/features/bookmark/domain/usecases/refresh_bookmark.dart';
import 'package:bacakomik_app/features/bookmark/presentation/bloc/bookmark_cubit.dart';
import 'package:bacakomik_app/features/history/data/datasources/history_local_data_source.dart';
import 'package:bacakomik_app/features/history/data/repositories/history_repository_impl.dart';
import 'package:bacakomik_app/features/history/domain/entities/read_history.dart';
import 'package:bacakomik_app/features/history/domain/usecases/history_usecases.dart';
import 'package:bacakomik_app/features/history/presentation/bloc/history_cubit.dart';
import 'package:bacakomik_app/features/migration/domain/usecases/apply_pending_reads.dart';
import 'package:bacakomik_app/features/migration/domain/usecases/import_library.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hive_ce/hive.dart';
import 'package:mocktail/mocktail.dart';

import '../fixtures/library_fixtures.dart';
import '../helpers/hive.dart';
import '../helpers/memory_pending_reads.dart';
import 'library_test.dart'
    show FixedClock, MockComicDetailRepository, RecordingNotifier, noCategories;

/// Times with microseconds, which storage drops.
DateTime micros(int ms) => DateTime.fromMicrosecondsSinceEpoch(ms * 1000 + 7);

ComicDetails comic(String key, {String title = 'Comic', int chapters = 2}) =>
    sampleComicDetails.copyWith(
      title: title,
      chapters: [
        for (var n = chapters; n >= 1; n--)
          Chapter(number: '$n', slug: '$key/$n', date: '-'),
      ],
    );

ReadHistory read(String comicKey, int n, int ms, {ComicDetails? details}) =>
    ReadHistory(
      slug: '$comicKey/$n',
      chapterNumber: '$n',
      readDate: micros(ms),
      comicDetails: details ?? comic(comicKey),
      comicSlug: comicKey,
    );

void main() {
  late Future<void> Function() tearDownHive;
  late FixedClock clock;
  late LibraryJournal journal;
  late HistoryRepositoryImpl historyRepo;

  HistoryCubit historyCubit() => HistoryCubit(
    GetHistory(historyRepo),
    SaveHistory(historyRepo),
    RemoveHistory(historyRepo),
    RemoveComicHistory(historyRepo),
    ClearHistory(historyRepo),
    clock,
  );

  /// What a full reload reads.
  Future<List<ReadHistory>> reloaded() async {
    final fresh = historyCubit();
    await fresh.load();
    return fresh.state;
  }

  setUp(() async {
    tearDownHive = await setUpTempHive();
    clock = FixedClock(micros(1000));
    journal = LibraryJournal(
      await Hive.openBox<String>(HiveBoxes.libraryDeletions),
      clock,
    );
    historyRepo = HistoryRepositoryImpl(
      HistoryLocalDataSourceImpl(
        await Hive.openBox<String>(HiveBoxes.historyEntries),
        await Hive.openBox<String>(HiveBoxes.historyComics),
      ),
      journal,
    );
  });

  tearDown(() => tearDownHive());

  group('HistoryCubit edits in memory', () {
    late HistoryCubit cubit;

    setUp(() async {
      cubit = historyCubit();
      await cubit.load();
    });

    test('every edit leaves the state a reload would read', () async {
      Future<void> matchesReload() async =>
          expect(cubit.state, await reloaded());

      await cubit.addHistoryList([
        read('x:a', 1, 100),
        read('x:b', 1, 300),
        read('x:a', 2, 200),
        // Same time as x:b/1: ties go by slug.
        read('x:c', 1, 300),
        read(
          'x:d',
          1,
          50,
        ).copyWith(readDate: DateTime.utc(1970, 1, 1, 0, 0, 1)),
      ]);
      await matchesReload();

      // New details for x:a reach its older entries too.
      final renamed = comic('x:a', title: 'Renamed', chapters: 3);
      await cubit.addHistoryList([read('x:a', 3, 400, details: renamed)]);
      await matchesReload();
      expect(
        cubit.state
            .where((h) => h.comicSlug == 'x:a')
            .map((h) => h.comicDetails),
        everyElement(renamed),
      );

      clock.value = micros(2000);
      await cubit.addHistory(
        slug: 'x:b/1',
        chapterNumber: '1',
        comicDetails: comic('x:b'),
        comicSlug: 'x:b',
        page: 3,
        pageCount: 20,
      );
      await matchesReload();

      // Same time for chapter 0 of both comics.
      await cubit.markAllRead({
        'x:e': comic('x:e', chapters: 3),
        'x:f': comic('x:f', chapters: 2),
      });
      await matchesReload();

      await cubit.removeHistoryList(['x:a/1', 'x:e/2', 'missing/1']);
      await matchesReload();

      await cubit.removeHistoryBySlug('x:b');
      await matchesReload();

      await cubit.markAllUnread(['x:e', 'x:f']);
      await matchesReload();

      await cubit.clearHistory();
      await matchesReload();
      expect(cubit.state, isEmpty);
    });

    test('edits update the index in place to what a rebuild holds', () async {
      final index = cubit.index;
      void matchesRebuild(String step) {
        // Patched, not rebuilt.
        expect(identical(cubit.index, index), isTrue, reason: step);
        final rebuilt = HistoryIndex(cubit.state);
        expect(cubit.index.perComic, rebuilt.perComic, reason: step);
        expect(cubit.index.latest, rebuilt.latest, reason: step);
        expect(cubit.index.comics.toSet(), rebuilt.comics.toSet());
        for (final c in ['x:a', 'x:b', 'x:c', 'x:e', 'x:f']) {
          expect(cubit.index.latestOf(c), rebuilt.latestOf(c), reason: step);
          expect(cubit.index.countOf(c), rebuilt.countOf(c), reason: step);
          expect(
            cubit.index.finishedCountOf(c),
            rebuilt.finishedCountOf(c),
            reason: step,
          );
        }
        for (final h in [...cubit.state, read('x:a', 9, 0)]) {
          expect(cubit.index.chapter(h.slug), rebuilt.chapter(h.slug));
        }
      }

      await cubit.addHistoryList([
        read('x:a', 1, 100),
        read('x:b', 1, 300),
        read('x:a', 2, 200),
        read('x:c', 1, 300),
      ]);
      matchesRebuild('add');

      final renamed = comic('x:a', title: 'Renamed', chapters: 3);
      await cubit.addHistoryList([read('x:a', 3, 50, details: renamed)]);
      matchesRebuild('rename');

      clock.value = micros(2000);
      await cubit.addHistory(
        slug: 'x:b/1',
        chapterNumber: '1',
        comicDetails: comic('x:b'),
        comicSlug: 'x:b',
        page: 3,
        pageCount: 20,
      );
      matchesRebuild('page');

      await cubit.markAllRead({
        'x:b': comic('x:b'),
        'x:e': comic('x:e', chapters: 3),
        'x:f': comic('x:f'),
      });
      matchesRebuild('mark read');

      await cubit.removeHistoryList(['x:a/1', 'x:e/2', 'missing/1']);
      matchesRebuild('remove');

      await cubit.removeHistoryBySlug('x:b');
      matchesRebuild('remove comic');

      await cubit.markAllUnread(['x:e', 'x:f', 'missing']);
      matchesRebuild('mark unread');

      await cubit.clearHistory();
      matchesRebuild('clear');
      expect(cubit.index.perComic, isEmpty);
    });

    test('an edit landing while a load reads is kept', () async {
      final loading = cubit.load();
      await cubit.addHistoryList([read('x:a', 1, 100)]);
      await loading;

      expect(cubit.state.map((h) => h.slug), ['x:a/1']);
      expect(cubit.state, await reloaded());
    });

    test('quiet saves fire no change; announcing saves the same entry '
        'normally', () async {
      await cubit.addHistoryList([read('x:a', 1, 100)]);
      await cubit.removeHistory('x:a/1');
      expect(journal.deleted(LibraryKind.history).keys, ['x:a/1']);

      var changes = 0;
      journal.changes.listen((_) => changes++);
      Future<void> readPage(int page) => cubit.addHistory(
        slug: 'x:a/1',
        chapterNumber: '1',
        comicDetails: comic('x:a'),
        comicSlug: 'x:a',
        page: page,
        pageCount: 20,
        quiet: true,
      );

      await readPage(1);
      clock.value = micros(1500);
      await readPage(2);
      expect(changes, 0);
      // A quiet save still clears the deletion record.
      expect(journal.deleted(LibraryKind.history), isEmpty);
      final saved = cubit.index.chapter('x:a/1')!;

      clock.value = micros(9000);
      await cubit.announce('x:a/1');
      expect(changes, 1);
      expect(cubit.index.chapter('x:a/1'), saved);
      expect(saved.page, 2);
      expect(saved.readDate, DateTime.fromMillisecondsSinceEpoch(1500));
      expect(cubit.state, await reloaded());

      // Nothing left to announce.
      await cubit.announce('x:a/1');
      expect(changes, 1);
    });
  });

  group('HistoryRepository', () {
    late Box<String> entries;
    late Box<String> comics;

    setUp(() {
      entries = Hive.box<String>(HiveBoxes.historyEntries);
      comics = Hive.box<String>(HiveBoxes.historyComics);
    });

    test("a comic's history is found by key prefix", () async {
      await historyRepo.saveHistory([
        read('x:a', 1, 1),
        read('x:a', 2, 2),
        read('x:ab', 1, 3),
        read('a', 1, 4),
        read('y:a', 1, 5),
      ]);
      var changes = 0;
      journal.changes.listen((_) => changes++);

      await historyRepo.removeComicHistory('x:a');

      expect(entries.keys, unorderedEquals(['x:ab/1', 'a/1', 'y:a/1']));
      expect(comics.keys, unorderedEquals(['x:ab', 'a', 'y:a']));
      expect(journal.deleted(LibraryKind.history).keys, {'x:a/1', 'x:a/2'});

      await historyRepo.removeComicsHistory(['x:ab', 'a']);

      expect(entries.keys, ['y:a/1']);
      expect(comics.keys, ['y:a']);
      expect(changes, 2);
    });

    test('removing entries prunes only their comics', () async {
      await historyRepo.saveHistory([
        read('x:a', 1, 1),
        read('x:a', 2, 2),
        read('x:b', 1, 3),
      ]);

      await historyRepo.removeHistory(['x:a/1', 'x:b/1']);
      expect(comics.keys, ['x:a']);

      await historyRepo.removeHistory(['x:a/2']);
      expect(comics.isEmpty, isTrue);
    });

    test('unchanged details are not written again', () async {
      final details = comic('x:a');
      await historyRepo.saveHistory([read('x:a', 1, 1, details: details)]);
      final stored = comics.get('x:a');

      await historyRepo.saveHistory([read('x:a', 2, 2, details: details)]);
      expect(identical(comics.get('x:a'), stored), isTrue);

      // An equal copy is compared by its JSON: still not written.
      await historyRepo.saveHistory([read('x:a', 2, 3)]);
      expect(identical(comics.get('x:a'), stored), isTrue);

      final changed = comic('x:a', chapters: 3);
      await historyRepo.saveHistory([read('x:a', 3, 4, details: changed)]);
      expect(comics.get('x:a'), isNot(stored));
      final history = (await historyRepo.getHistory()).getOrElse(
        (f) => fail('$f'),
      );
      expect(history.map((h) => h.comicDetails), everyElement(changed));
      // One details object per comic.
      expect(
        identical(history[0].comicDetails, history[1].comicDetails),
        isTrue,
      );
    });
  });

  group('BookmarkCubit edits in memory', () {
    setUpAll(() => registerFallbackValue(<Chapter>[]));

    late BookmarkRepositoryImpl repo;
    late MockComicDetailRepository comicDetails;
    late MemoryPendingReads pendingReads;
    late BookmarkCubit cubit;

    BookmarkCubit bookmarkCubit() => BookmarkCubit(
      GetBookmarks(repo),
      SaveBookmarks(repo),
      RemoveBookmarks(repo),
      RefreshBookmark(
        repo,
        comicDetails,
        ApplyPendingReads(pendingReads, historyRepo, clock),
        clock,
      ),
      MigrateComic(repo, historyRepo, noCategories(), clock),
      CompleteImportedComic(
        repo,
        ApplyPendingReads(pendingReads, historyRepo, clock),
      ),
      RecordingNotifier(),
      clock,
    );

    Future<void> matchesReload() async {
      final fresh = bookmarkCubit();
      await fresh.load();
      expect(cubit.state, fresh.state);
    }

    setUp(() async {
      repo = BookmarkRepositoryImpl(
        BookmarkLocalDataSourceImpl(
          await Hive.openBox<String>(HiveBoxes.bookmarks),
        ),
        journal,
      );
      comicDetails = MockComicDetailRepository();
      pendingReads = MemoryPendingReads();
      await repo.saveBookmarks([
        Bookmark(
          slug: 'x:a',
          comicDetails: comic('x:a'),
          updatedDate: micros(100),
        ),
        Bookmark(
          slug: 'x:c',
          comicDetails: comic('x:c'),
          updatedDate: micros(300),
        ),
        // Same date as x:c: ties go by slug.
        Bookmark(
          slug: 'x:b',
          comicDetails: comic('x:b'),
          updatedDate: micros(300),
        ),
      ]);
      cubit = bookmarkCubit();
      await cubit.load();
    });

    test(
      'add, refresh and remove leave the state a reload would read',
      () async {
        expect(cubit.state.map((b) => b.slug), ['x:b', 'x:c', 'x:a']);

        await cubit.addBookmark(comic('x:d'), 'x:d');
        await matchesReload();
        expect(cubit.state.first.slug, 'x:d');

        clock.value = micros(5000);
        when(() => comicDetails.getChapters('x:a'))
            .thenAnswer((_) async => right(comic('x:a', chapters: 5).chapters));
        when(() => comicDetails.getSeries('x:a', any()))
            .thenAnswer((_) async => right(comic('x:a', chapters: 5)));
        when(() => comicDetails.getChapters('x:c'))
            .thenAnswer((_) async => right(comic('x:c').chapters));
        await cubit.updateBookmarkList(['x:a', 'x:c']);
        await matchesReload();
        expect(cubit.state.first.slug, 'x:a');

        await cubit.removeBookmarkList(['x:b', 'missing']);
        await matchesReload();
        expect(cubit.state.map((b) => b.slug), ['x:a', 'x:d', 'x:c']);
      },
    );

    test('comicLoaded completes an imported bookmark in place', () async {
      await repo.saveBookmarks([
        Bookmark(
          slug: 'x:i',
          comicDetails: placeholderDetails('x:i', 'Imported'),
          updatedDate: micros(200),
        ),
      ]);
      await cubit.load();

      await cubit.comicLoaded('x:i', comic('x:i'));

      await matchesReload();
      expect(cubit.state.map((b) => b.slug), ['x:b', 'x:c', 'x:i', 'x:a']);
      expect(
        cubit.state.firstWhere((b) => b.slug == 'x:i').comicDetails,
        comic('x:i'),
      );
    });

    test('comicLoaded leaves the state alone when nothing changed', () async {
      final before = cubit.state;

      expect(
        await cubit.comicLoaded('x:a', comic('x:a', chapters: 9)),
        isFalse,
      );
      expect(await cubit.comicLoaded('x:z', comic('x:z')), isFalse);

      expect(identical(cubit.state, before), isTrue);
    });
  });
}
