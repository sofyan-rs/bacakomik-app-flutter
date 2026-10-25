import 'package:bacakomik_app/core/domain/entities/comic_details.dart';
import 'package:bacakomik_app/core/storage/hive_boxes.dart';
import 'package:bacakomik_app/core/storage/library_journal.dart';
import 'package:bacakomik_app/features/bookmark/data/datasources/bookmark_local_data_source.dart';
import 'package:bacakomik_app/features/bookmark/data/repositories/bookmark_repository_impl.dart';
import 'package:bacakomik_app/features/category/data/datasources/category_local_data_source.dart';
import 'package:bacakomik_app/features/history/data/datasources/history_local_data_source.dart';
import 'package:bacakomik_app/features/history/data/repositories/history_repository_impl.dart';
import 'package:bacakomik_app/features/history/domain/entities/read_history.dart';
import 'package:bacakomik_app/features/sync/data/repositories/sync_repository_impl.dart';
import 'package:bacakomik_app/features/sync/domain/entities/sync_snapshot.dart';
import 'package:bacakomik_app/features/sync/domain/usecases/migrate_library.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

import '../fixtures/library_fixtures.dart';
import '../helpers/hive.dart';
import 'sync_test.dart'
    show
        FixedClock,
        MockAuth,
        MockDrive,
        at,
        bookmark,
        category,
        currentDetails,
        inCategories,
        read;

ReadHistory readOf(String slug, int date, ComicDetails details) =>
    read(slug, date).copyWith(comicDetails: details);

/// What `sameAs` was before: a deep comparison of sorted copies.
bool deepSame(SyncSnapshot a, SyncSnapshot b) => a.sorted() == b.sorted();

void main() {
  group('SyncSnapshot.merge', () {
    final legacy = sampleComicDetails;
    final a = SyncSnapshot(
      bookmarks: [
        bookmark('a', 1),
        bookmark('b', 5).copyWith(addedDate: at(1)),
        bookmark('d', 2).copyWith(comicDetails: legacy),
      ],
      history: [read('a/1', 1), read('a/2', 9), read('c/1', 4)],
      deletedBookmarks: {'x': at(3)},
      deletedHistory: {'a/2': at(10), 'old/1': at(1)},
      categories: [category('k', 1)],
      comicCategories: [
        inCategories('a', ['k'], 1),
      ],
    );
    final b = SyncSnapshot(
      bookmarks: [
        bookmark('b', 5, title: 'Other'),
        bookmark('c', 7),
        bookmark('d', 2),
        bookmark('x', 2),
      ],
      history: [read('a/1', 2), read('b/1', 3), read('c/1', 4, page: 3)],
      deletedHistory: {'c/1': at(4)},
      categories: [
        category('k', 2, name: 'New'),
        category('m', 1),
      ],
      comicCategories: [
        inCategories('b', ['m'], 1),
      ],
    );

    SyncSnapshot reversed(SyncSnapshot s) => s.copyWith(
      bookmarks: s.bookmarks.reversed.toList(),
      history: s.history.reversed.toList(),
      categories: s.categories.reversed.toList(),
      comicCategories: s.comicCategories.reversed.toList(),
    );

    test('sorted inputs merge in one pass to the same result', () {
      for (final keep in [0, 2]) {
        final fast = SyncSnapshot.merge(a, b, keepDeletionsSince: at(keep));
        final slow = SyncSnapshot.merge(
          reversed(a),
          reversed(b),
          keepDeletionsSince: at(keep),
        );
        expect(fast, slow);
      }
      final merged = SyncSnapshot.merge(a, b, keepDeletionsSince: at(0));
      expect(merged.bookmarks.map((b) => b.slug), ['a', 'b', 'c', 'd']);
      // Equal dates: the first side's copy, unless only the other has a
      // source.
      expect(merged.bookmarks[1].comicDetails.title, 'Solo');
      expect(merged.bookmarks[1].addedDate, at(1));
      expect(merged.bookmarks[3].comicDetails.source, isNotNull);
      expect(merged.history.map((h) => h.slug), ['a/1', 'b/1']);
    });
  });

  group('SyncSnapshot.sameAs', () {
    final details = currentDetails;
    final equalCopy = currentDetails.copyWith(
      chapters: [...currentDetails.chapters],
    );
    final otherChapters = currentDetails.copyWith(
      chapters: currentDetails.chapters.take(1).toList(),
    );
    final base = SyncSnapshot(
      bookmarks: [bookmark('a', 1), bookmark('b', 2)],
      history: [
        readOf('a/1', 1, details),
        readOf('a/2', 2, details),
        readOf('b/1', 3, details),
      ],
      deletedHistory: {'z/1': at(5)},
      categories: [category('k', 1)],
      comicCategories: [
        inCategories('a', ['k'], 1),
      ],
    );

    final variants = <String, SyncSnapshot>{
      'same': base,
      'reordered': base.copyWith(
        bookmarks: base.bookmarks.reversed.toList(),
        history: base.history.reversed.toList(),
      ),
      'equal details, other objects': base.copyWith(
        history: [
          for (final h in base.history) h.copyWith(comicDetails: equalCopy),
        ],
      ),
      'details differ for one entry': base.copyWith(
        history: [
          base.history[0],
          base.history[1].copyWith(comicDetails: otherChapters),
          base.history[2],
        ],
      ),
      'page differs': base.copyWith(
        history: [
          base.history[0],
          base.history[1].copyWith(page: 4, pageCount: 9),
          base.history[2],
        ],
      ),
      'bookmark details differ': base.copyWith(
        bookmarks: [
          base.bookmarks[0].copyWith(comicDetails: otherChapters),
          base.bookmarks[1],
        ],
      ),
      'added date differs': base.copyWith(
        bookmarks: [
          base.bookmarks[0].copyWith(addedDate: at(1)),
          base.bookmarks[1],
        ],
      ),
      'entry missing': base.copyWith(history: base.history.take(2).toList()),
      'deletion differs': base.copyWith(deletedHistory: {'z/1': at(6)}),
      'category differs': base.copyWith(categories: [category('k', 2)]),
    };

    for (final MapEntry(key: name, value: other) in variants.entries) {
      test('agrees with a deep comparison: $name', () {
        expect(base.sameAs(other), deepSame(base, other));
        expect(other.sameAs(base), deepSame(other, base));
      });
    }
  });

  group('local library in the background', () {
    late Future<void> Function() tearDownHive;
    late SyncRepositoryImpl sync;
    late BookmarkRepositoryImpl bookmarks;
    late HistoryRepositoryImpl history;

    setUp(() async {
      tearDownHive = await setUpTempHive();
      final clock = FixedClock(at(1000));
      final journal = LibraryJournal(
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

    Future<SyncSnapshot> readLocal() async =>
        (await sync.readLocal()).getOrElse((f) => fail('$f'));

    test('entries of one comic share one details object', () async {
      await history.saveHistory([
        read('a/1', 1),
        read('a/2', 2),
        read('b/1', 3),
      ]);

      final local = await readLocal();

      expect(local.history.map((h) => h.slug), ['a/1', 'a/2', 'b/1']);
      expect(
        identical(local.history[0].comicDetails, local.history[1].comicDetails),
        isTrue,
      );
    });

    test('writeLocal writes only what changed', () async {
      await bookmarks.saveBookmarks([bookmark('a', 1), bookmark('b', 2)]);
      await history.saveHistory([read('a/1', 1), read('a/2', 2)]);
      final box = Hive.box<String>(HiveBoxes.bookmarks);
      final entries = Hive.box<String>(HiveBoxes.historyEntries);
      final (storedA, storedEntry) = (box.get('a'), entries.get('a/1'));

      final local = await readLocal();
      await sync.writeLocal(
        local.copyWith(
          bookmarks: [local.bookmarks[0], bookmark('c', 3)],
          history: [local.history[0], read('a/2', 5)],
        ),
      );

      expect(identical(box.get('a'), storedA), isTrue);
      expect(identical(entries.get('a/1'), storedEntry), isTrue);
      expect(box.keys, ['a', 'c']);
      expect((await readLocal()).history[1].readDate, at(5));
    });

    test('anyLocalComic decodes only the keys asked for', () async {
      await bookmarks.saveBookmarks([
        bookmark('solo', 1),
        bookmark('voratoon:a', 2).copyWith(comicDetails: sampleComicDetails),
      ]);
      await history.saveHistory([read('w:b/1', 1).copyWith(comicSlug: 'w:b')]);
      final tested = <String>[];
      Future<bool> any(bool Function(String, ComicDetails) test) async =>
          (await sync.anyLocalComic(
            where: MigrateSnapshot.isLegacyKey,
            test: (key, details) {
              tested.add(key);
              return test(key, details);
            },
          )).getOrElse((f) => fail('$f'));

      expect(await any(MigrateSnapshot.isLegacy), isFalse);
      expect(tested, ['solo']);

      await history.saveHistory([
        read(
          'old/1',
          1,
        ).copyWith(comicSlug: 'old', comicDetails: sampleComicDetails),
      ]);
      expect(await any(MigrateSnapshot.isLegacy), isTrue);
    });
  });
}
