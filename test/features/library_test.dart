import 'dart:async';
import 'dart:convert';

import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:bacakomik_app/core/domain/entities/comic_details.dart';
import 'package:bacakomik_app/core/error/failures.dart';
import 'package:bacakomik_app/core/notifications/progress_notifier.dart';
import 'package:bacakomik_app/core/storage/hive_boxes.dart';
import 'package:bacakomik_app/core/storage/library_journal.dart';
import 'package:bacakomik_app/core/utils/clock.dart';
import 'package:bacakomik_app/features/bookmark/data/datasources/bookmark_local_data_source.dart';
import 'package:bacakomik_app/features/bookmark/data/repositories/bookmark_repository_impl.dart';
import 'package:bacakomik_app/features/bookmark/domain/entities/bookmark.dart';
import 'package:bacakomik_app/features/bookmark/domain/repositories/bookmark_repository.dart';
import 'package:bacakomik_app/features/bookmark/domain/usecases/bookmark_usecases.dart';
import 'package:bacakomik_app/features/bookmark/domain/usecases/migrate_comic.dart';
import 'package:bacakomik_app/features/bookmark/domain/usecases/refresh_bookmark.dart';
import 'package:bacakomik_app/features/bookmark/presentation/bloc/bookmark_cubit.dart';
import 'package:bacakomik_app/features/category/domain/entities/category.dart';
import 'package:bacakomik_app/features/category/domain/repositories/category_repository.dart';
import 'package:bacakomik_app/features/comic_detail/domain/repositories/comic_detail_repository.dart';
import 'package:bacakomik_app/features/history/data/datasources/history_local_data_source.dart';
import 'package:bacakomik_app/features/history/data/repositories/history_repository_impl.dart';
import 'package:bacakomik_app/features/history/domain/entities/read_history.dart';
import 'package:bacakomik_app/features/history/domain/repositories/history_repository.dart';
import 'package:bacakomik_app/features/history/domain/usecases/history_usecases.dart';
import 'package:bacakomik_app/features/history/presentation/bloc/history_cubit.dart';
import 'package:bacakomik_app/features/migration/domain/usecases/apply_pending_reads.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hive_ce/hive.dart';
import 'package:mocktail/mocktail.dart';

import '../fixtures/library_fixtures.dart';
import '../helpers/hive.dart';
import '../helpers/memory_pending_reads.dart';

class FixedClock implements Clock {
  FixedClock(this.value);

  DateTime value;

  @override
  DateTime now() => value;
}

class MockComicDetailRepository extends Mock implements ComicDetailRepository {}

class MockBookmarkRepository extends Mock implements BookmarkRepository {}

class MockHistoryRepository extends Mock implements HistoryRepository {}

class MockCategoryRepository extends Mock implements CategoryRepository {}

/// A category repository where no comic is in a category yet.
MockCategoryRepository noCategories() {
  final repo = MockCategoryRepository();
  when(() => repo.getComicCategories()).thenAnswer((_) async => right({}));
  when(() => repo.saveComicCategories(any())).thenAnswer((_) async => right(unit));
  return repo;
}

/// Records `done/total` for progress and the title of the end notification.
class RecordingNotifier implements ProgressNotifier {
  final calls = <String>[];

  @override
  Future<void> progress(
    int id, {
    required String title,
    required int done,
    required int total,
    bool cancelable = false,
  }) async => calls.add('$done/$total');

  final cancels = StreamController<int>.broadcast();

  @override
  Stream<int> get cancelRequests => cancels.stream;

  @override
  Future<void> finish(int id, {String? title, String? body}) async =>
      calls.add('finish ${title ?? '-'}');
}

const details = sampleComicDetails;

DateTime at(int ms) => DateTime.fromMillisecondsSinceEpoch(ms);

ReadHistory history(String slug, String comicSlug, int readDate) => ReadHistory(
  slug: slug,
  chapterNumber: slug.split('/').last,
  readDate: at(readDate),
  comicDetails: details,
  comicSlug: comicSlug,
);

Bookmark bookmark(String slug, String title, int updatedDate) => Bookmark(
  slug: slug,
  comicDetails: details.copyWith(title: title),
  updatedDate: at(updatedDate),
);

void main() {
  late Future<void> Function() tearDownHive;
  late FixedClock clock;

  setUp(() async {
    tearDownHive = await setUpTempHive();
    clock = FixedClock(at(1000));
  });

  tearDown(() => tearDownHive());

  group('HistoryCubit', () {
    late HistoryCubit cubit;

    setUp(() async {
      final repo = HistoryRepositoryImpl(
        HistoryLocalDataSourceImpl(
          await Hive.openBox<String>(HiveBoxes.historyEntries),
          await Hive.openBox<String>(HiveBoxes.historyComics),
        ),
        LibraryJournal(
          await Hive.openBox<String>(HiveBoxes.libraryDeletions),
          clock,
        ),
      );
      cubit = HistoryCubit(
        GetHistory(repo),
        SaveHistory(repo),
        RemoveHistory(repo),
        RemoveComicHistory(repo),
        ClearHistory(repo),
        clock,
      );
      await cubit.addHistoryList([
        history('a/1', 'a', 100),
        history('b/1', 'b', 300),
        history('a/2', 'a', 200),
      ]);
    });

    test('state is newest first', () {
      expect(cubit.state.map((h) => h.slug), ['b/1', 'a/2', 'a/1']);
    });

    test("stores each comic's details once, not per chapter", () {
      final entries = Hive.box<String>(HiveBoxes.historyEntries);
      final comics = Hive.box<String>(HiveBoxes.historyComics);

      expect(entries.length, 3);
      expect(comics.keys, unorderedEquals(['a', 'b']));
      final entry = jsonDecode(entries.get('a/1')!) as Map<String, dynamic>;
      expect(
        entry.keys,
        unorderedEquals(['slug', 'chapterNumber', 'readDate', 'comicSlug']),
      );
    });

    test("drops a comic's details with its last chapter", () async {
      final comics = Hive.box<String>(HiveBoxes.historyComics);

      await cubit.removeHistory('b/1');
      expect(comics.keys, ['a']);

      await cubit.removeHistoryList(['a/1']);
      expect(comics.keys, ['a']);

      await cubit.removeHistoryBySlug('a');
      expect(comics.isEmpty, isTrue);
    });

    test('addHistory stamps now and replaces the same chapter', () async {
      await cubit.addHistory(
        slug: 'a/1',
        chapterNumber: '1',
        comicDetails: details,
        comicSlug: 'a',
        page: 9,
        pageCount: 10,
      );

      expect(cubit.state.map((h) => h.slug), ['a/1', 'b/1', 'a/2']);
      expect(cubit.state.first.readDate, at(1000));
      expect(cubit.state, hasLength(3));
    });

    test('addHistory keeps the page until the last one is reached', () async {
      Future<void> read(int page) => cubit.addHistory(
        slug: 'c/1',
        chapterNumber: '1',
        comicDetails: details,
        comicSlug: 'c',
        page: page,
        pageCount: 24,
      );

      await read(4);
      expect(cubit.index.isFinished('c/1'), isFalse);
      expect(cubit.index.chapter('c/1')?.pageCount, 24);
      expect(cubit.resumePage('c/1'), 4);

      await read(23);
      expect(cubit.index.isFinished('c/1'), isTrue);
      expect(cubit.resumePage('c/1'), 0);

      // Reading a finished chapter again does not unfinish it.
      await read(2);
      expect(cubit.index.isFinished('c/1'), isTrue);
    });

    test('queries', () {
      expect(cubit.latestHistory.slug, 'b/1');
      expect(cubit.getLatestHistoryBySlug('a')!.slug, 'a/2');
      expect(cubit.getLatestHistoryBySlug('z'), isNull);
      expect(cubit.getHistoryCountBySlug('a'), 2);
      expect(cubit.isInHistory('a/1'), isTrue);
      expect(cubit.latestHistories.map((h) => h.latestHistory.slug), [
        'b/1',
        'a/2',
      ]);
    });

    test('remove variants and clear', () async {
      await cubit.removeHistory('b/1');
      expect(cubit.state.map((h) => h.slug), ['a/2', 'a/1']);

      await cubit.removeHistoryBySlug('a');
      expect(cubit.state, isEmpty);

      await cubit.addHistoryList([history('c/1', 'c', 1)]);
      await cubit.clearHistory();
      expect(cubit.state, isEmpty);
    });

    test('persists across cubit instances', () async {
      final repo = HistoryRepositoryImpl(
        HistoryLocalDataSourceImpl(
          Hive.box<String>(HiveBoxes.historyEntries),
          Hive.box<String>(HiveBoxes.historyComics),
        ),
        LibraryJournal(Hive.box<String>(HiveBoxes.libraryDeletions), clock),
      );
      final fresh = HistoryCubit(
        GetHistory(repo),
        SaveHistory(repo),
        RemoveHistory(repo),
        RemoveComicHistory(repo),
        ClearHistory(repo),
        clock,
      );

      await fresh.load();

      expect(fresh.state, hasLength(3));
    });
  });

  group('Bookmarks', () {
    late BookmarkRepositoryImpl repo;
    late HistoryRepositoryImpl historyRepo;
    late MockComicDetailRepository comicDetails;
    late BookmarkCubit cubit;
    late RecordingNotifier notifier;
    late MemoryPendingReads pendingReads;

    setUp(() async {
      repo = BookmarkRepositoryImpl(
        BookmarkLocalDataSourceImpl(
          await Hive.openBox<String>(HiveBoxes.bookmarks),
        ),
        LibraryJournal(
          await Hive.openBox<String>(HiveBoxes.libraryDeletions),
          clock,
        ),
      );
      historyRepo = HistoryRepositoryImpl(
        HistoryLocalDataSourceImpl(
          await Hive.openBox<String>(HiveBoxes.historyEntries),
          await Hive.openBox<String>(HiveBoxes.historyComics),
        ),
        LibraryJournal(Hive.box<String>(HiveBoxes.libraryDeletions), clock),
      );
      comicDetails = MockComicDetailRepository();
      pendingReads = MemoryPendingReads();
      notifier = RecordingNotifier();
      cubit = BookmarkCubit(
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
        notifier,
        clock,
      );
      await repo.saveBookmarks([
        bookmark('a', 'Alpha', 100),
        bookmark('b', 'Beta', 300),
        bookmark('c', 'Gamma', 200),
      ]);
      await cubit.load();
    });

    test('state is newest first', () {
      expect(cubit.state.map((b) => b.slug), ['b', 'c', 'a']);
    });

    test('addBookmark puts entry first', () async {
      await cubit.addBookmark(details, 'd');

      expect(cubit.state.first.slug, 'd');
      expect(cubit.isBookmark('d'), isTrue);
    });

    test('searchBookmark filters by lowercase title, newest first', () {
      expect(cubit.searchBookmark('a').map((b) => b.slug), ['b', 'c', 'a']);
      expect(cubit.searchBookmark('gam').map((b) => b.slug), ['c']);
    });

    test('removeBookmarkList', () async {
      await cubit.removeBookmarkList(['a', 'c']);

      expect(cubit.state.map((b) => b.slug), ['b']);
    });

    test('refresh updates only comics with new chapters', () async {
      final moreChapters = details.copyWith(
        chapters: [
          ...details.chapters,
          const Chapter(number: '3', slug: 'x/3', date: '-'),
        ],
      );
      when(() => comicDetails.getComicDetails('a'))
          .thenAnswer((_) async => right(moreChapters));
      when(() => comicDetails.getComicDetails('b'))
          .thenAnswer((_) async => left(const NetworkFailure()));
      when(() => comicDetails.getComicDetails('c'))
          .thenAnswer((_) async => right(details.copyWith(title: 'Gamma')));
      clock.value = at(5000);

      await cubit.updateBookmarkList(['a', 'b', 'c']);

      expect(cubit.state.map((b) => b.slug), ['a', 'b', 'c']);
      expect(cubit.state.first.updatedDate, at(5000));
      expect(cubit.state.first.comicDetails.chapters, hasLength(3));
      expect(cubit.state[1].updatedDate, at(300));
      expect(cubit.state[2].updatedDate, at(200));
    });

    test('refresh checks only the given group; a second call joins the run',
        () async {
      final first = Completer<Either<Failure, ComicDetails>>();
      when(() => comicDetails.getComicDetails('a'))
          .thenAnswer((_) => first.future);
      when(() => comicDetails.getComicDetails('c'))
          .thenAnswer((_) async => right(details));

      final run = cubit.updateBookmarkList(['a']);
      final joined = cubit.updateBookmarkList(['a', 'c']);
      first.complete(right(details));
      await Future.wait([run, joined]);

      verifyNever(() => comicDetails.getComicDetails('b'));
      verify(() => comicDetails.getComicDetails('a')).called(1);
      expect(notifier.calls, ['0/1', '1/2', 'finish -']);
    });

    test('refresh reports how many comics changed', () async {
      when(() => comicDetails.getComicDetails(any())).thenAnswer(
        (_) async => right(
          details.copyWith(
            chapters: [
              ...details.chapters,
              const Chapter(number: '9', slug: 'x/9', date: '-'),
            ],
          ),
        ),
      );

      await cubit.updateBookmarkList(['a', 'b']);

      expect(notifier.calls.last, 'finish ${AppText.bookmarksUpdated}');
    });

    test('Cancel in the notification stops the run', () async {
      when(() => comicDetails.getComicDetails('b'))
          .thenAnswer((_) => Completer<Either<Failure, ComicDetails>>().future);

      final run = cubit.updateBookmarkList(['a', 'b', 'c']);
      await Future<void>.delayed(Duration.zero);
      notifier.cancels.add(ProgressIds.bookmarkRefresh);
      await run;

      verifyNever(() => comicDetails.getComicDetails('a'));
      verifyNever(() => comicDetails.getComicDetails('c'));
      expect(notifier.calls.last, 'finish -');
    });

    test('refresh applies imported progress and reports it at once', () async {
      when(() => comicDetails.getComicDetails('a'))
          .thenAnswer((_) async => right(details));
      when(() => comicDetails.getComicDetails('b'))
          .thenAnswer((_) async => right(details));
      await pendingReads.save({'a': '1'});
      final changes = <void>[];
      final sub = cubit.historyChanges.listen(changes.add);

      await cubit.updateBookmarkList(['a', 'b']);
      await Future<void>.delayed(Duration.zero);

      expect(changes, hasLength(1));
      expect(pendingReads.values, isEmpty);
      final read = (await historyRepo.getHistory()).getOrElse((_) => []);
      expect(read.map((h) => (h.comicSlug, h.chapterNumber)), [('a', '1')]);
      await sub.cancel();
    });

    test('sameSeriesAs finds other entries with the same title', () async {
      await repo.saveBookmarks([bookmark('voratoon:a', 'alpha!', 50)]);
      await cubit.load();

      expect(cubit.sameSeriesAs('a', 'Alpha').map((b) => b.slug), [
        'voratoon:a',
      ]);
      expect(cubit.sameSeriesAs('x', 'Delta'), isEmpty);
    });

    test('migrate moves the bookmark and matching history', () async {
      await historyRepo.saveHistory([
        history('a/1', 'a', 10),
        history('a/9', 'a', 20),
        history('b/1', 'b', 30),
      ]);
      final target = details.copyWith(
        source: 'voratoon',
        chapters: const [
          Chapter(number: '2', slug: 'voratoon:a/2', date: '-'),
          Chapter(number: '1', slug: 'voratoon:a/1', date: '-'),
        ],
      );
      clock.value = at(7000);

      await cubit.migrate(from: 'a', to: 'voratoon:a', details: target);

      expect(cubit.isBookmark('a'), isFalse);
      expect(cubit.state.first.slug, 'voratoon:a');
      expect(cubit.state.first.comicDetails, target);
      expect(cubit.state.first.updatedDate, at(7000));
      final entries = (await historyRepo.getHistory()).getOrElse(
        (f) => throw f,
      );
      expect(
        entries.map((h) => (h.slug, h.comicSlug, h.readDate)),
        unorderedEquals([
          ('voratoon:a/1', 'voratoon:a', at(10)),
          ('b/1', 'b', at(30)),
        ]),
      );
    });
  });

  group('MigrateComic', () {
    late MockBookmarkRepository bookmarks;
    late MockHistoryRepository historyRepo;
    late MockCategoryRepository categories;
    late MigrateComic migrate;
    final target = details.copyWith(
      chapters: const [Chapter(number: '1', slug: 'v:a/1', date: '-')],
    );

    setUpAll(() {
      registerFallbackValue(<String>[]);
      registerFallbackValue(<ComicCategories>[]);
    });

    setUp(() {
      bookmarks = MockBookmarkRepository();
      historyRepo = MockHistoryRepository();
      categories = noCategories();
      migrate = MigrateComic(bookmarks, historyRepo, categories, clock);
      when(() => bookmarks.saveBookmarks(any()))
          .thenAnswer((_) async => right(unit));
      when(() => bookmarks.removeBookmarks(any()))
          .thenAnswer((_) async => right(unit));
      when(() => historyRepo.saveHistory(any()))
          .thenAnswer((_) async => right(unit));
      when(() => historyRepo.removeComicHistory(any()))
          .thenAnswer((_) async => right(unit));
    });

    test('without read chapters only moves the bookmark', () async {
      when(() => historyRepo.getHistory())
          .thenAnswer((_) async => right([history('a/5', 'a', 1)]));

      final result = await migrate((from: 'a', to: 'v:a', details: target));

      expect(result, right(unit));
      final saved =
          verify(() => bookmarks.saveBookmarks(captureAny())).captured.single
              as List<Bookmark>;
      expect(saved.single.slug, 'v:a');
      expect(saved.single.updatedDate, at(1000));
      verifyNever(() => historyRepo.saveHistory(any()));
      verify(() => historyRepo.removeComicHistory('a')).called(1);
      verify(() => bookmarks.removeBookmarks(['a'])).called(1);
    });

    test('keeps the categories of the comic', () async {
      when(() => historyRepo.getHistory()).thenAnswer((_) async => right([]));
      when(() => categories.getComicCategories()).thenAnswer(
        (_) async => right({
          'a': ComicCategories(slug: 'a', categoryIds: ['x'], updatedDate: at(1)),
        }),
      );

      await migrate((from: 'a', to: 'v:a', details: target));

      final saved =
          verify(() => categories.saveComicCategories(captureAny()))
                  .captured
                  .single
              as List<ComicCategories>;
      expect(saved.single.slug, 'v:a');
      expect(saved.single.categoryIds, ['x']);
    });

    test('joins the categories of a bookmark it replaces', () async {
      when(() => historyRepo.getHistory()).thenAnswer((_) async => right([]));
      when(() => categories.getComicCategories()).thenAnswer(
        (_) async => right({
          'a': ComicCategories(slug: 'a', categoryIds: ['x'], updatedDate: at(1)),
          'v:a': ComicCategories(
            slug: 'v:a',
            categoryIds: ['y', 'x'],
            updatedDate: at(1),
          ),
        }),
      );

      await migrate((from: 'a', to: 'v:a', details: target));

      final saved =
          verify(() => categories.saveComicCategories(captureAny()))
                  .captured
                  .single
              as List<ComicCategories>;
      expect(saved.single.categoryIds, ['y', 'x']);
    });

    test('history read failure changes nothing', () async {
      when(() => historyRepo.getHistory())
          .thenAnswer((_) async => left(const CacheFailure('broken')));

      final result = await migrate((from: 'a', to: 'v:a', details: target));

      expect(result.isLeft(), isTrue);
      verifyNever(() => bookmarks.saveBookmarks(any()));
      verifyNever(() => bookmarks.removeBookmarks(any()));
    });

    test('stops at the first failing step, keeping the old entries', () async {
      when(() => historyRepo.getHistory())
          .thenAnswer((_) async => right([history('a/1', 'a', 1)]));
      when(() => historyRepo.saveHistory(any()))
          .thenAnswer((_) async => left(const CacheFailure('full')));

      final result = await migrate((from: 'a', to: 'v:a', details: target));

      expect(result.getLeft().toNullable()?.message, 'full');
      verifyNever(() => historyRepo.removeComicHistory(any()));
      verifyNever(() => bookmarks.removeBookmarks(any()));
    });
  });

  group('sameSeries', () {
    final library = [
      bookmark('a', 'Solo Leveling', 1),
      bookmark('voratoon:a', 'solo  leveling!', 2),
      bookmark('b', 'Solo Leveling: Ragnarok', 3),
    ];

    test('matches titles ignoring case, spacing and punctuation', () {
      expect(sameSeries(library, 'x', 'SOLO-LEVELING').map((b) => b.slug), [
        'a',
        'voratoon:a',
      ]);
    });

    test('excludes the comic itself', () {
      expect(sameSeries(library, 'a', 'Solo Leveling').map((b) => b.slug), [
        'voratoon:a',
      ]);
    });

    test('a title of only punctuation matches nothing', () {
      expect(sameSeries([bookmark('q', '?!', 1)], 'x', '!?'), isEmpty);
    });

    test('normalizeTitle keeps letters and digits of any script', () {
      expect(normalizeTitle("Hero’s Return: 2"), 'herosreturn2');
      expect(normalizeTitle('나 혼자만 레벨업'), '나혼자만레벨업');
    });
  });

  test('ReadHistory queries do not depend on list order', () {
    final list = [history('a/1', 'a', 100), history('a/2', 'a', 200)];

    expect(list.latest!.slug, 'a/2');
    expect(list.reversed.toList().latest!.slug, 'a/2');
    expect(const <ReadHistory>[].latest, isNull);
  });
}
