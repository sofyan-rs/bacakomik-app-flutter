import 'package:bacakomik_app/core/domain/entities/comic_details.dart';
import 'package:bacakomik_app/core/storage/hive_boxes.dart';
import 'package:bacakomik_app/core/storage/library_journal.dart';
import 'package:bacakomik_app/core/utils/clock.dart';
import 'package:bacakomik_app/features/history/data/datasources/history_local_data_source.dart';
import 'package:bacakomik_app/features/history/data/repositories/history_repository_impl.dart';
import 'package:bacakomik_app/features/history/domain/usecases/history_usecases.dart';
import 'package:bacakomik_app/features/history/presentation/bloc/history_cubit.dart';
import 'package:bacakomik_app/features/reader/presentation/pages/read_chapter_screen.dart';
import 'package:bacakomik_app/features/reader/presentation/reader_wakelock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

import '../../fixtures/library_fixtures.dart';
import '../../helpers/hive.dart';

class _FixedClock implements Clock {
  _FixedClock(this.value);

  DateTime value;

  @override
  DateTime now() => value;
}

DateTime _at(int ms) => DateTime.fromMillisecondsSinceEpoch(ms);

void main() {
  group('ReaderWakelock', () {
    late List<bool> applied;
    late ReaderWakelock wakelock;

    setUp(() {
      applied = [];
      wakelock = ReaderWakelock(applied.add);
    });

    test('stays on while the next chapter replaces the reader', () {
      wakelock.acquire(keepOn: true);
      // The next chapter's reader starts before the old one is disposed.
      wakelock.acquire(keepOn: true);
      wakelock.release();

      expect(wakelock.enabled, isTrue);
      expect(applied, [true]);

      wakelock.release();
      expect(wakelock.enabled, isFalse);
      expect(applied, [true, false]);
    });

    test('also when the old reader goes first', () {
      wakelock
        ..acquire(keepOn: true)
        ..release()
        ..acquire(keepOn: true);
      expect(wakelock.enabled, isTrue);
      expect(wakelock.holders, 1);
    });

    test('follows the setting while a reader is open', () {
      wakelock.acquire(keepOn: false);
      expect(wakelock.enabled, isFalse);
      wakelock.setKeepOn(true);
      expect(wakelock.enabled, isTrue);
      wakelock
        ..release()
        ..release();
      expect(wakelock.holders, 0);
      expect(applied, [false, true, false]);
    });
  });

  test('page number of a chapter without pages does not throw', () {
    expect(shownPageNumber(0, 0), 0);
    expect(shownPageNumber(0, 3), 1);
    // The end item shows the last page.
    expect(shownPageNumber(3, 3), 3);
  });

  group('HistoryCubit reader saves', () {
    late Future<void> Function() tearDownHive;
    late HistoryCubit cubit;

    setUp(() async {
      tearDownHive = await setUpTempHive();
      final clock = _FixedClock(_at(1000));
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
    });

    tearDown(() async {
      await cubit.close();
      await tearDownHive();
    });

    Future<void> save(int page, int pageCount, {bool canFinish = true}) =>
        cubit.addHistory(
          slug: 'a/1',
          chapterNumber: '1',
          comicDetails: sampleComicDetails,
          comicSlug: 'a',
          page: page,
          pageCount: pageCount,
          canFinish: canFinish,
        );

    test('a chapter without pages is not recorded', () async {
      await save(0, 0);
      expect(cubit.state, isEmpty);
      expect(Hive.box<String>(HiveBoxes.historyEntries).isEmpty, isTrue);
    });

    test('opening a one-page chapter does not finish it', () async {
      await save(0, 1, canFinish: false);
      expect(cubit.index.isFinished('a/1'), isFalse);
      expect(cubit.index.chapter('a/1')?.pageCount, 1);

      // Still on it a moment later.
      await save(0, 1);
      expect(cubit.index.isFinished('a/1'), isTrue);
    });

    test('the end card is saved as the last page', () async {
      // Opening a chapter at its end card (index 13 of 13 pages) showed
      // "14 / 13" in the chapter list.
      await save(13, 13, canFinish: false);
      expect(cubit.index.chapter('a/1')?.page, 12);
      expect(cubit.index.isFinished('a/1'), isFalse);
    });

    test('markAllRead dates the highest number latest in any order', () async {
      final oldestFirst = sampleComicDetails.copyWith(
        chapters: const [
          Chapter(number: '1', slug: 'b/1', date: '-'),
          Chapter(number: '2', slug: 'b/2', date: '-'),
          Chapter(number: '10', slug: 'b/10', date: '-'),
        ],
      );
      await cubit.markAllRead({'b': oldestFirst});

      expect(cubit.getLatestHistoryBySlug('b')!.slug, 'b/10');
      expect(cubit.state.map((h) => h.slug), ['b/10', 'b/2', 'b/1']);
    });
  });
}
