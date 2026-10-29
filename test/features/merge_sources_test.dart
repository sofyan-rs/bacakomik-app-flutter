import 'package:bacakomik_app/core/domain/entities/comic_details.dart';
import 'package:bacakomik_app/core/error/failures.dart';
import 'package:bacakomik_app/core/storage/hive_boxes.dart';
import 'package:bacakomik_app/core/storage/library_journal.dart';
import 'package:bacakomik_app/core/utils/clock.dart';
import 'package:bacakomik_app/features/bookmark/data/datasources/bookmark_local_data_source.dart';
import 'package:bacakomik_app/features/bookmark/data/models/bookmark_model.dart';
import 'package:bacakomik_app/features/bookmark/data/repositories/bookmark_repository_impl.dart';
import 'package:bacakomik_app/features/bookmark/domain/entities/bookmark.dart';
import 'package:bacakomik_app/features/bookmark/domain/entities/merged_chapters.dart';
import 'package:bacakomik_app/features/bookmark/domain/usecases/merge_sources.dart';
import 'package:bacakomik_app/features/category/domain/repositories/category_repository.dart';
import 'package:bacakomik_app/features/comic_detail/domain/repositories/comic_detail_repository.dart';
import 'package:bacakomik_app/features/history/data/datasources/history_local_data_source.dart';
import 'package:bacakomik_app/features/history/data/repositories/history_repository_impl.dart';
import 'package:bacakomik_app/features/history/domain/entities/read_history.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hive_ce/hive.dart';
import 'package:mocktail/mocktail.dart';

import '../fixtures/library_fixtures.dart';
import '../helpers/hive.dart';
import '../helpers/memory_pending_reads.dart';

class FixedClock implements Clock {
  @override
  DateTime now() => DateTime.fromMillisecondsSinceEpoch(1000);
}

class MockComicDetailRepository extends Mock implements ComicDetailRepository {}

class MockCategoryRepository extends Mock implements CategoryRepository {}

Chapter ch(String key, String number) =>
    Chapter(number: number, slug: '$key/$number', date: '-');

ReadHistory read(String slug, String comicSlug) => ReadHistory(
  slug: slug,
  chapterNumber: slug.split('/').last,
  readDate: DateTime.fromMillisecondsSinceEpoch(500),
  comicDetails: sampleComicDetails,
  comicSlug: comicSlug,
);

Bookmark bookmark(String slug, List<Chapter> chapters) => Bookmark(
  slug: slug,
  comicDetails: sampleComicDetails.copyWith(chapters: chapters),
  updatedDate: DateTime.fromMillisecondsSinceEpoch(100),
);

void main() {
  group('mergeChapters', () {
    test('takes each number from the first source that has it', () {
      final merged = mergeChapters([
        [ch('a', '2'), ch('a', '1')],
        [ch('b', '3'), ch('b', '2'), ch('b', '1.5')],
      ]);
      expect(merged.map((c) => c.slug), ['b/3', 'a/2', 'b/1.5', 'a/1']);
    });

    test('keeps every copy of a number when not deduplicating', () {
      final merged = mergeChapters([
        [ch('a', '2'), ch('a', '1')],
        [ch('b', '3'), ch('b', '2')],
      ], dedupe: false);
      expect(merged.map((c) => c.slug), ['b/3', 'a/2', 'b/2', 'a/1']);
    });

    test('neighbours skip the copies of the same number', () {
      final list = [ch('b', '3'), ch('a', '2'), ch('b', '2'), ch('a', '1')];
      final ofB2 = neighboursIn(list, 2);
      expect(ofB2.next?.slug, 'b/3');
      expect(ofB2.previous?.slug, 'a/1');
      // Of the copies of 2, the first (most wanted) one.
      expect(neighboursIn(list, 3).next?.slug, 'a/2');
      expect(neighboursIn(list, 0).next, isNull);
    });

    test('a list from several series is merged', () {
      expect(isMergedList([ch('a', '1'), ch('a', '2')]), isFalse);
      expect(isMergedList([ch('a', '1'), ch('v:b', '2')]), isTrue);
      expect(seriesKeyOfChapter('v:b/2'), 'v:b');
    });
  });

  test('BookmarkModel keeps merged keys, and omits them when none', () {
    final merged = bookmark('a', const []).copyWith(mergedKeys: ['a', 'v:b']);
    expect(
      BookmarkModel.fromJson(BookmarkModel.fromEntity(merged).toJson())
          .toEntity()
          .mergedKeys,
      ['a', 'v:b'],
    );
    expect(
      BookmarkModel.fromJson(
        BookmarkModel.fromEntity(merged.copyWith(keepDuplicates: true))
            .toJson(),
      ).toEntity().keepDuplicates,
      isTrue,
    );
    expect(
      BookmarkModel.fromEntity(bookmark('a', const [])).toJson(),
      isNot(contains('mergedKeys')),
    );
  });

  group('with a library', () {
    late Future<void> Function() tearDownHive;
    late BookmarkRepositoryImpl bookmarks;
    late HistoryRepositoryImpl history;
    late MockComicDetailRepository comics;
    late MemoryPendingReads pending;
    late MergeComic merge;

    setUp(() async {
      tearDownHive = await setUpTempHive();
      final journal = LibraryJournal(
        await Hive.openBox<String>(HiveBoxes.libraryDeletions),
        FixedClock(),
      );
      bookmarks = BookmarkRepositoryImpl(
        BookmarkLocalDataSourceImpl(
          await Hive.openBox<String>(HiveBoxes.bookmarks),
        ),
        journal,
      );
      history = HistoryRepositoryImpl(
        HistoryLocalDataSourceImpl(
          await Hive.openBox<String>(HiveBoxes.historyEntries),
          await Hive.openBox<String>(HiveBoxes.historyComics),
        ),
        journal,
      );
      comics = MockComicDetailRepository();
      pending = MemoryPendingReads();
      final categories = MockCategoryRepository();
      when(() => categories.getComicCategories())
          .thenAnswer((_) async => right({}));
      merge = MergeComic(
        bookmarks,
        history,
        categories,
        comics,
        pending,
        AlignMergedHistory(history),
        FixedClock(),
      );
    });

    tearDown(() => tearDownHive());

    Future<Bookmark?> stored(String key) async =>
        (await bookmarks.getBookmark(key)).getOrElse((f) => throw f);

    Future<List<ReadHistory>> entries() async =>
        (await history.getHistory()).getOrElse((f) => throw f);

    test('merges a bookmarked series: one entry, its history kept', () async {
      await bookmarks.saveBookmarks([
        bookmark('a', [ch('a', '2'), ch('a', '1')]),
        bookmark('v:b', [ch('v:b', '3'), ch('v:b', '2')]),
      ]);
      await history.saveHistory([read('v:b/3', 'v:b'), read('a/1', 'a')]);

      final result = await merge((into: 'a', add: 'v:b', details: null));

      expect(result, right(unit));
      expect(await stored('v:b'), isNull);
      final merged = (await stored('a'))!;
      expect(merged.mergedKeys, ['a', 'v:b']);
      expect(merged.comicDetails.chapters.map((c) => c.slug), [
        'v:b/3',
        'a/2',
        'a/1',
      ]);
      final saved = await entries();
      expect(
        {for (final h in saved) h.slug: h.comicSlug},
        {'v:b/3': 'a', 'a/1': 'a'},
      );
    });

    test('a read chapter moves to the source now taking its number', () async {
      await bookmarks.saveBookmarks([
        bookmark('a', [ch('a', '1')]),
      ]);
      await history.saveHistory([read('a/1', 'a')]);

      await merge((
        into: 'a',
        add: 'v:b',
        details: sampleComicDetails.copyWith(chapters: [ch('v:b', '1')]),
      ));
      // v:b first: chapter 1 now comes from it.
      await SetMergedSources(bookmarks)((
        key: 'a',
        keys: ['v:b', 'a'],
        keepDuplicates: null,
      ));
      final chapters = (await stored('a'))!.comicDetails.chapters;
      expect(chapters.map((c) => c.slug), ['a/1']);

      final changed = await AlignMergedHistory(history)((
        key: 'a',
        chapters: [ch('v:b', '1')],
      ));

      expect(changed, right(true));
      expect((await entries()).map((h) => (h.slug, h.comicSlug)), [
        ('v:b/1', 'a'),
      ]);
    });

    test('removing a comic finds its entries of other series', () async {
      await history.saveHistory([read('v:b/3', 'a'), read('a/1', 'a')]);

      await history.removeComicHistory('a');

      expect(await entries(), isEmpty);
    });

    test('FetchMergedChapters keeps a failed source\'s chapters', () async {
      when(() => comics.getChapters('a'))
          .thenAnswer((_) async => right([ch('a', '2')]));
      when(() => comics.getChapters('v:b'))
          .thenAnswer((_) async => left(const ServerFailure('down')));

      final result = await FetchMergedChapters(comics)(
        ['a', 'v:b'],
        [ch('v:b', '3'), ch('a', '1')],
      );

      expect(result.getOrElse((f) => throw f).map((c) => c.slug), [
        'v:b/3',
        'a/2',
      ]);
    });
  });
}
