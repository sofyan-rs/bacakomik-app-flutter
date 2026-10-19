import 'dart:convert';

import 'package:bacakomik_app/core/domain/entities/comic_details.dart';
import 'package:bacakomik_app/core/error/failures.dart';
import 'package:bacakomik_app/core/storage/hive_boxes.dart';
import 'package:bacakomik_app/core/utils/clock.dart';
import 'package:bacakomik_app/features/bookmark/data/datasources/bookmark_local_data_source.dart';
import 'package:bacakomik_app/features/bookmark/data/repositories/bookmark_repository_impl.dart';
import 'package:bacakomik_app/features/bookmark/domain/entities/bookmark.dart';
import 'package:bacakomik_app/features/bookmark/domain/usecases/bookmark_usecases.dart';
import 'package:bacakomik_app/features/bookmark/domain/usecases/refresh_bookmarks.dart';
import 'package:bacakomik_app/features/bookmark/presentation/bloc/bookmark_cubit.dart';
import 'package:bacakomik_app/features/comic_detail/domain/repositories/comic_detail_repository.dart';
import 'package:bacakomik_app/features/history/data/datasources/history_local_data_source.dart';
import 'package:bacakomik_app/features/history/data/repositories/history_repository_impl.dart';
import 'package:bacakomik_app/features/history/domain/entities/read_history.dart';
import 'package:bacakomik_app/features/history/domain/usecases/history_usecases.dart';
import 'package:bacakomik_app/features/history/presentation/bloc/history_cubit.dart';
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

class MockComicDetailRepository extends Mock implements ComicDetailRepository {}

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
      );

      expect(cubit.state.map((h) => h.slug), ['a/1', 'b/1', 'a/2']);
      expect(cubit.state.first.readDate, at(1000));
      expect(cubit.state, hasLength(3));
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
    late MockComicDetailRepository comicDetails;
    late BookmarkCubit cubit;

    setUp(() async {
      repo = BookmarkRepositoryImpl(
        BookmarkLocalDataSourceImpl(
          await Hive.openBox<String>(HiveBoxes.bookmarks),
        ),
      );
      comicDetails = MockComicDetailRepository();
      cubit = BookmarkCubit(
        GetBookmarks(repo),
        SaveBookmarks(repo),
        RemoveBookmarks(repo),
        RefreshBookmarks(repo, comicDetails, clock),
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

      await cubit.updateBookmarkList();

      expect(cubit.state.map((b) => b.slug), ['a', 'b', 'c']);
      expect(cubit.state.first.updatedDate, at(5000));
      expect(cubit.state.first.comicDetails.chapters, hasLength(3));
      expect(cubit.state[1].updatedDate, at(300));
      expect(cubit.state[2].updatedDate, at(200));
    });
  });

  test('ReadHistory queries do not depend on list order', () {
    final list = [history('a/1', 'a', 100), history('a/2', 'a', 200)];

    expect(list.latest!.slug, 'a/2');
    expect(list.reversed.toList().latest!.slug, 'a/2');
    expect(const <ReadHistory>[].latest, isNull);
  });
}
