import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:bacakomik_app/core/domain/entities/comic.dart';
import 'package:bacakomik_app/core/domain/entities/comic_details.dart';
import 'package:bacakomik_app/core/source/extension_meta.dart';
import 'package:bacakomik_app/core/storage/hive_boxes.dart';
import 'package:bacakomik_app/core/storage/library_journal.dart';
import 'package:bacakomik_app/core/utils/clock.dart';
import 'package:bacakomik_app/features/bookmark/data/datasources/bookmark_local_data_source.dart';
import 'package:bacakomik_app/features/bookmark/data/repositories/bookmark_repository_impl.dart';
import 'package:bacakomik_app/features/bookmark/domain/entities/bookmark.dart';
import 'package:bacakomik_app/features/category/data/datasources/category_local_data_source.dart';
import 'package:bacakomik_app/features/category/data/repositories/category_repository_impl.dart';
import 'package:bacakomik_app/features/history/data/datasources/history_local_data_source.dart';
import 'package:bacakomik_app/features/history/data/repositories/history_repository_impl.dart';
import 'package:bacakomik_app/features/history/domain/entities/read_history.dart';
import 'package:bacakomik_app/features/migration/data/datasources/mihon_backup_parser.dart';
import 'package:bacakomik_app/features/migration/domain/entities/comix_csv.dart';
import 'package:bacakomik_app/features/migration/domain/entities/library_import.dart';
import 'package:bacakomik_app/features/migration/domain/entities/mihon_backup.dart';
import 'package:bacakomik_app/features/migration/domain/entities/mihon_import_plan.dart';
import 'package:bacakomik_app/features/migration/domain/usecases/apply_pending_reads.dart';
import 'package:bacakomik_app/features/migration/domain/usecases/import_library.dart';
import 'package:bacakomik_app/features/migration/domain/usecases/source_migration.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

import '../fixtures/library_fixtures.dart';
import '../helpers/hive.dart';
import '../helpers/memory_pending_reads.dart';

class FixedClock implements Clock {
  FixedClock(this.value);

  DateTime value;

  @override
  DateTime now() => value;
}

ExtensionMeta meta(
  String id,
  String name, {
  List<String> patterns = const [],
  List<String> languages = const [],
  String version = '1.0.0',
}) => ExtensionMeta(
  id: id,
  name: name,
  lang: languages.isEmpty ? 'en' : 'all',
  version: version,
  apiVersion: 1,
  baseUrl: 'https://$id.example',
  file: '$id.js',
  sha256: '',
  urlPatterns: patterns,
  languages: languages,
);

final mangafire = meta(
  'mangafire',
  'MangaFire',
  patterns: [r'^/(?:title|manga)/([^/?#]+)'],
);
final westmanga = meta(
  'westmanga',
  'WestManga',
  patterns: [r'^/(?:manga|comic)/([^/?#]+)'],
);
final mangadex = meta(
  'mangadex',
  'MangaDex',
  languages: ['en', 'id'],
  patterns: [
    r'^/(?:manga|title)/([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})',
  ],
);

/// Protobuf writer for test backups.
class _Proto {
  final _bytes = BytesBuilder();

  void _varint(int value) {
    var v = value;
    while (v >= 0x80 || v < 0) {
      _bytes.addByte((v & 0x7f) | 0x80);
      v = v >>> 7;
    }
    _bytes.addByte(v);
  }

  void int64(int field, int value) {
    _varint(field << 3);
    _varint(value);
  }

  void bytes(int field, List<int> value) {
    _varint(field << 3 | 2);
    _varint(value.length);
    _bytes.add(value);
  }

  void string(int field, String value) => bytes(field, utf8.encode(value));

  void float(int field, double value) {
    _varint(field << 3 | 5);
    _bytes.add(
      (ByteData(4)..setFloat32(0, value, Endian.little)).buffer.asUint8List(),
    );
  }

  List<int> get value => _bytes.toBytes();
}

List<int> manga(
  int source,
  String url,
  String title, {
  bool? favorite,
  List<int> categories = const [],
  List<(double, bool)> chapters = const [],
}) {
  final p = _Proto()
    ..int64(1, source)
    ..string(2, url)
    ..string(3, title);
  for (final (number, read) in chapters) {
    final c = _Proto();
    if (read) c.int64(4, 1);
    c.float(9, number);
    p.bytes(16, c.value);
  }
  for (final c in categories) {
    p.int64(17, c);
  }
  if (favorite != null) p.int64(100, favorite ? 1 : 0);
  return p.value;
}

void main() {
  group('ExtensionMeta.slugFromUrl', () {
    test('reads paths and full URLs', () {
      expect(mangafire.slugFromUrl('/title/kx1mw-dukedom'), 'kx1mw-dukedom');
      expect(
        mangafire.slugFromUrl('https://mangafire.to/manga/abc.123?x=1'),
        'abc.123',
      );
      expect(westmanga.slugFromUrl('/manga/oreaku/'), 'oreaku');
      expect(westmanga.slugFromUrl('/series/oreaku/'), isNull);
    });

    test('comix hid stops at the title part', () {
      final comix = meta(
        'comix',
        'Comix',
        patterns: [r'^/(?:title/)?([a-z0-9]+)(?=[-/?#]|$)'],
      );
      expect(comix.slugFromUrl('/m76m'), 'm76m');
      expect(
        comix.slugFromUrl('https://comix.to/title/m76m-high-school'),
        'm76m',
      );
    });

    test('keeps its patterns per language', () {
      expect(
        mangadex
            .forLanguage('id')
            .slugFromUrl('/manga/3c524d15-6523-42e0-91a8-f516dd57fc7a'),
        '3c524d15-6523-42e0-91a8-f516dd57fc7a',
      );
    });

    test('round-trips through JSON', () {
      final copy = ExtensionMeta.fromJson(mangafire.toJson());
      expect(copy.urlPatterns, mangafire.urlPatterns);
    });
  });

  group('Mihon backup', () {
    test('source ids are MD5 of name/lang/version', () {
      expect(mihonSourceId('MangaDex', 'en'), 2499283573021220255);
      expect(mihonSourceId('MangaDex', 'id'), 3807502156582598786);
      expect(mihonSourceId('MangaFire', 'en'), 6084907896154116083);
    });

    test('parses a gzipped backup', () {
      final category = _Proto()
        ..string(1, 'Manhwa')
        ..int64(2, 1);
      final source = _Proto()
        ..string(1, 'MangaFire')
        ..int64(2, 6084907896154116083);
      final backup = _Proto()
        ..bytes(
          1,
          manga(
            6084907896154116083,
            '/title/a',
            'A',
            categories: [1],
            chapters: [(43, false), (42.2, true), (7, true), (-1, true)],
          ),
        )
        ..bytes(1, manga(6084907896154116083, '/title/b', 'B', favorite: false))
        ..bytes(2, category.value)
        ..bytes(101, source.value);

      final parsed = parseMihonBackup(gzip.encode(backup.value));

      expect(parsed.sourceNames, {6084907896154116083: 'MangaFire'});
      expect(parsed.categories, {1: 'Manhwa'});
      expect(parsed.manga.map((m) => m.lastRead), ['42.2', null]);
      expect(
        parsed.manga.map((m) => (m.title, m.favorite, m.categories.join(','))),
        [('A', true, '1'), ('B', false, '')],
      );
    });

    test('rejects other files', () {
      expect(
        () => parseMihonBackup(utf8.encode('{"version": 2}')),
        throwsFormatException,
      );
    });

    test('plans per source: matched first, languages by id', () {
      final dexId = mihonSourceId('MangaDex', 'id');
      final backup = MihonBackup(
        sourceNames: {1: 'West Manga', 2: 'Doujindesu', dexId: 'MangaDex'},
        categories: {0: 'Manga'},
        manga: [
          const MihonManga(
            sourceId: 1,
            url: '/manga/a/',
            title: 'A',
            categories: [0],
          ),
          const MihonManga(sourceId: 1, url: '/manga/a/', title: 'A again'),
          const MihonManga(sourceId: 1, url: '/odd/link', title: 'Odd'),
          const MihonManga(
            sourceId: 1,
            url: '/manga/c/',
            title: 'C',
            favorite: false,
          ),
          const MihonManga(sourceId: 2, url: '/manga/d/', title: 'D'),
          MihonManga(
            sourceId: dexId,
            url: '/manga/3c524d15-6523-42e0-91a8-f516dd57fc7a',
            title: 'Dex',
          ),
        ],
      );

      final groups = planMihonImport(backup, [
        westmanga,
        // An installed copy without patterns loses to the repo's.
        meta('westmanga', 'WestManga'),
        mangadex,
      ]);

      expect(groups.map((g) => (g.name, g.source?.id, g.supported)), [
        ('West Manga', 'westmanga', true),
        ('MangaDex', 'mangadex-id', true),
        ('Doujindesu', null, false),
      ]);
      final west = groups.first;
      expect(
        west.entries.map((e) => (e.key, e.title, e.categories.join(','))),
        [('westmanga:a', 'A', 'Manga')],
      );
      expect(west.unreadable, 1);
      expect(
        groups[1].entries.single.key,
        'mangadex-id:3c524d15-6523-42e0-91a8-f516dd57fc7a',
      );
    });
  });

  group('parseComixCsv', () {
    test('reads titles and last chapters', () {
      const csv =
          'title,chapter,folder,url_mal,url_al,url_mu\r\n'
          '"Hikaru to Hikaru",7.000,Reading,https://myanimelist.net/manga/1,,\r\n'
          '"Saikyou, no Maou",42.200,Reading,,,\r\n'
          '"Harem ""dorei"" desu.",0.000,Reading,,,\r\n';
      expect(parseComixCsv(csv).map((e) => (e.title, e.lastRead)), [
        ('Hikaru to Hikaru', '7'),
        ('Saikyou, no Maou', '42.2'),
        ('Harem "dorei" desu.', null),
      ]);
    });

    test('needs a title column', () {
      expect(() => parseComixCsv('name\nA\n'), throwsFormatException);
    });
  });

  test('exactMatch ignores case and punctuation, not ambiguity', () {
    Comic comic(String slug, String title) => Comic(
      title: title,
      coverImg: '',
      slug: slug,
      type: '',
      completed: false,
      rating: '',
      latestChapter: '',
    );
    expect(
      exactMatch("The Hero’s Return", [
        comic('a', 'Hero Return'),
        comic('b', "the hero's return"),
      ])?.slug,
      'b',
    );
    expect(exactMatch('X', [comic('a', 'x'), comic('b', 'X!')]), isNull);
  });

  group('import and pending reads', () {
    late Future<void> Function() tearDownHive;
    late BookmarkRepositoryImpl bookmarks;
    late HistoryRepositoryImpl history;
    late CategoryRepositoryImpl categories;
    late MemoryPendingReads pending;
    final clock = FixedClock(DateTime(2026, 10, 25));

    setUp(() async {
      tearDownHive = await setUpTempHive();
      final journal = LibraryJournal(
        await Hive.openBox<String>(HiveBoxes.libraryDeletions),
        clock,
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
      categories = CategoryRepositoryImpl(
        CategoryLocalDataSourceImpl(
          await Hive.openBox<String>(HiveBoxes.categories),
          await Hive.openBox<String>(HiveBoxes.comicCategories),
        ),
        journal,
      );
      pending = MemoryPendingReads();
    });

    tearDown(() => tearDownHive());

    test('ImportLibrary adds placeholders in order, skips existing', () async {
      await bookmarks.saveBookmarks([
        Bookmark(
          slug: 'comix:old',
          comicDetails: sampleComicDetails,
          updatedDate: DateTime(2020),
        ),
      ]);

      final result = await ImportLibrary(bookmarks, categories, pending, clock)(
        const [
          ImportEntry(key: 'comix:a', title: 'A', categories: ['Manhwa']),
          ImportEntry(key: 'comix:old', title: 'Old', lastRead: '3'),
          ImportEntry(key: 'b', title: 'B', categories: ['manhwa', 'New']),
        ],
      );

      final r = result.getOrElse((f) => fail('$f'));
      expect((r.added, r.existing), (2, 1));
      final saved = bookmarks.getBookmarks().then(
        (b) => b.getOrElse((_) => const []),
      );
      final list = await saved;
      expect(list.map((b) => b.slug), ['comix:a', 'b', 'comix:old']);
      expect(list.first.comicDetails.isPlaceholder, isTrue);
      // A bare key belongs to the default source, which keeps it out of the
      // legacy migration.
      expect(list[1].comicDetails.source, 'bacakomik');
      expect(list.last.comicDetails, sampleComicDetails);
      expect(pending.values, {'comix:old': '3'});

      final made = (await categories.getCategories()).getOrElse(
        (_) => const [],
      );
      expect(made.map((c) => c.name), ['Manhwa', 'New']);
      final bySlug = (await categories.getComicCategories()).getOrElse(
        (_) => const {},
      );
      expect(bySlug['comix:a']!.categoryIds, [made.first.id]);
      expect(bySlug['b']!.categoryIds, [made.first.id, made.last.id]);
    });

    test(
      'ImportLibrary skips a series bookmarked from another source',
      () async {
        await bookmarks.saveBookmarks([
          Bookmark(
            slug: 'voratoon:oreaku',
            comicDetails: sampleComicDetails.copyWith(title: 'OreAku, Ore wa!'),
            updatedDate: DateTime(2020),
          ),
        ]);

        final result =
            await ImportLibrary(bookmarks, categories, pending, clock)(const [
              ImportEntry(
                key: 'westmanga:oreaku',
                title: 'OreAku Ore wa',
                lastRead: '48',
              ),
              ImportEntry(key: 'comix:x', title: 'X', lastRead: '3'),
              ImportEntry(key: 'mangafire:x', title: 'x!', lastRead: '9'),
            ]);

        final r = result.getOrElse((f) => fail('$f'));
        expect((r.added, r.existing, r.sameTitle), (1, 0, 2));
        final keys = (await bookmarks.getBookmarks())
            .getOrElse((_) => const [])
            .map((b) => b.slug)
            .toSet();
        expect(keys, {'voratoon:oreaku', 'comix:x'});
        // Progress goes to the bookmark the series lives under, highest wins.
        expect(pending.values, {'voratoon:oreaku': '48', 'comix:x': '9'});
      },
    );

    test('ApplyPendingReads marks chapters up to the last read', () async {
      const details = ComicDetails(
        title: 'A',
        coverImg: 'c',
        alternativeTitle: '',
        released: '',
        status: '',
        totalChapter: '',
        author: '',
        type: '',
        rating: '',
        synopsis: '',
        genres: [],
        chapters: [
          Chapter(number: '8', slug: 'comix:a/8', date: ''),
          Chapter(number: '7.5', slug: 'comix:a/7.5', date: ''),
          Chapter(number: '7', slug: 'comix:a/7', date: ''),
          Chapter(number: '1', slug: 'comix:a/1', date: ''),
        ],
      );
      final apply = ApplyPendingReads(pending, history, clock);
      // Nothing waits: nothing happens.
      expect(
        (await apply((key: 'comix:a', details: details)))
            .getOrElse((_) => true),
        isFalse,
      );

      await history.saveHistory([
        ReadHistory(
          slug: 'comix:a/1',
          chapterNumber: '1',
          readDate: DateTime(2020),
          comicDetails: details,
          comicSlug: 'comix:a',
          page: 4,
          pageCount: 10,
        ),
      ]);
      await pending.save({'comix:a': '7'});
      // An empty chapter list keeps it waiting.
      await apply((
        key: 'comix:a',
        details: placeholderDetails('comix:a', 'A'),
      ));
      expect(pending.values, isNotEmpty);

      final changed = await apply((key: 'comix:a', details: details));

      expect(changed.getOrElse((_) => false), isTrue);
      expect(pending.values, isEmpty);
      final read = (await history.getHistory()).getOrElse((_) => const []);
      expect(read.map((h) => (h.slug, h.page)).toSet(), {
        ('comix:a/7', null),
        ('comix:a/1', 4),
      });
      // The last read chapter is the newest entry.
      expect(read.newestFirst.first.slug, 'comix:a/7');
    });

    test(
      'CompleteImportedComic gives a placeholder bookmark its details',
      () async {
        await bookmarks.saveBookmarks([
          Bookmark(
            slug: 'b',
            comicDetails: placeholderDetails('b', 'Solo'),
            updatedDate: DateTime(2021),
          ),
        ]);
        final complete = CompleteImportedComic(
          bookmarks,
          ApplyPendingReads(pending, history, clock),
        );

        await complete((key: 'b', details: sampleComicDetails));

        final saved = (await bookmarks.getBookmarks())
            .getOrElse((_) => const [])
            .single;
        expect(saved.comicDetails, sampleComicDetails);
        expect(saved.updatedDate, DateTime(2021));

        // Details already loaded are left alone.
        final other = sampleComicDetails.copyWith(title: 'Other');
        await complete((key: 'b', details: other));
        expect(
          (await bookmarks.getBookmarks())
              .getOrElse((_) => const [])
              .single
              .comicDetails
              .title,
          'Solo Leveling',
        );
      },
    );
  });
}
