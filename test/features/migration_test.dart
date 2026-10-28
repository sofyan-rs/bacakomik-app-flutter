import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:bacakomik_app/core/domain/entities/comic.dart';
import 'package:bacakomik_app/core/domain/entities/comic_details.dart';
import 'package:bacakomik_app/core/error/failures.dart';
import 'package:bacakomik_app/core/source/extension_meta.dart';
import 'package:bacakomik_app/core/storage/hive_boxes.dart';
import 'package:bacakomik_app/core/storage/library_journal.dart';
import 'package:bacakomik_app/core/utils/clock.dart';
import 'package:bacakomik_app/features/bookmark/data/datasources/bookmark_local_data_source.dart';
import 'package:bacakomik_app/features/bookmark/data/repositories/bookmark_repository_impl.dart';
import 'package:bacakomik_app/features/bookmark/domain/entities/bookmark.dart';
import 'package:bacakomik_app/features/bookmark/domain/usecases/migrate_comic.dart';
import 'package:bacakomik_app/features/category/data/datasources/category_local_data_source.dart';
import 'package:bacakomik_app/features/category/data/repositories/category_repository_impl.dart';
import 'package:bacakomik_app/features/history/data/datasources/history_local_data_source.dart';
import 'package:bacakomik_app/features/history/data/repositories/history_repository_impl.dart';
import 'package:bacakomik_app/features/history/domain/entities/read_history.dart';
import 'package:bacakomik_app/features/migration/data/datasources/mihon_backup_parser.dart';
import 'package:bacakomik_app/features/migration/data/repositories/pending_read_repository_impl.dart';
import 'package:bacakomik_app/features/migration/domain/entities/comix_csv.dart';
import 'package:bacakomik_app/features/migration/domain/entities/library_import.dart';
import 'package:bacakomik_app/features/migration/domain/entities/mihon_backup.dart';
import 'package:bacakomik_app/features/migration/domain/entities/mihon_import_plan.dart';
import 'package:bacakomik_app/features/migration/domain/entities/pending_read.dart';
import 'package:bacakomik_app/features/migration/domain/usecases/apply_pending_reads.dart';
import 'package:bacakomik_app/features/migration/domain/usecases/import_library.dart';
import 'package:bacakomik_app/features/migration/domain/usecases/source_migration.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
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

/// Pending reads where an import adds to the comic right after it was read.
class _ImportingMeanwhile extends MemoryPendingReads {
  @override
  Future<Either<Failure, PendingRead?>> pendingOf(String key) async {
    final read = await super.pendingOf(key);
    values[key] = PendingRead.upTo('9');
    return read;
  }
}

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
  List<List<int>> fullChapters = const [],
  List<(String, DateTime)> history = const [],
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
  for (final c in fullChapters) {
    p.bytes(16, c);
  }
  for (final (chapter, date) in history) {
    final h = _Proto()
      ..string(1, chapter)
      ..int64(2, date.millisecondsSinceEpoch)
      ..int64(3, 60000);
    p.bytes(104, h.value);
  }
  for (final c in categories) {
    p.int64(17, c);
  }
  if (favorite != null) p.int64(100, favorite ? 1 : 0);
  return p.value;
}

/// A `BackupChapter` with the fields the import reads, and some it skips.
List<int> backupChapter(
  String url,
  double? number, {
  bool read = false,
  DateTime? fetched,
  DateTime? uploaded,
}) {
  final c = _Proto()
    ..string(1, url)
    ..string(2, 'Chapter $number')
    ..string(3, 'Group');
  if (read) c.int64(4, 1);
  c.int64(6, 12); // lastPageRead: skipped
  if (fetched != null) c.int64(7, fetched.millisecondsSinceEpoch);
  if (uploaded != null) c.int64(8, uploaded.millisecondsSinceEpoch);
  if (number != null) c.float(9, number);
  c.int64(10, 3);
  return c.value;
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

    test('a huge length is a truncated file, not a range error', () {
      // Field 1, length-delimited, length 2^63 - 1.
      final bytes = [0x0a, for (var i = 0; i < 8; i++) 0xff, 0x7f, 1, 2];
      expect(
        () => parseMihonBackup(bytes),
        throwsA(
          isFormatException.having(
            (e) => e.message,
            'message',
            'Truncated backup',
          ),
        ),
      );
    });

    test('skips groups instead of rejecting the file', () {
      final backup = _Proto()
        .._varint(50 << 3 | 3)
        ..int64(1, 5)
        ..string(2, 'inside')
        .._varint(50 << 3 | 4)
        ..bytes(1, manga(1, '/a', 'A'));

      expect(parseMihonBackup(backup.value).manga.map((m) => m.title), ['A']);
    });

    test('parses chapters and their history', () {
      final t = DateTime(2026, 10, 1, 12);
      // Legacy history (field 102) numbers its fields from 0.
      final legacy = _Proto()
        ..string(0, '/c/0')
        ..int64(1, t.subtract(const Duration(days: 1)).millisecondsSinceEpoch);
      final backup = _Proto()
        ..bytes(1, [
          ...manga(
            1,
            '/manga/a/',
            'A',
            fullChapters: [
              backupChapter(
                '/c/2',
                2,
                read: true,
                fetched: t,
                uploaded: t.subtract(const Duration(days: 3)),
              ),
              // Chapter number 0 is left out of the file, like any default.
              backupChapter('/c/0', null),
            ],
            history: [('/c/2', t.add(const Duration(hours: 1)))],
          ),
          ...(_Proto()..bytes(102, legacy.value)).value,
        ]);

      final m = parseMihonBackup(gzip.encode(backup.value)).manga.single;

      expect(m.chapters.map((c) => (c.url, c.numberText, c.read, c.fetched)), [
        ('/c/2', '2', true, t),
        ('/c/0', '0', false, null),
      ]);
      expect(m.chapters.first.uploaded, t.subtract(const Duration(days: 3)));
      expect(m.history, {
        '/c/2': t.add(const Duration(hours: 1)),
        '/c/0': t.subtract(const Duration(days: 1)),
      });
      expect(m.lastRead, '2');
    });

    test('importChapters: newest first, one per number, dates like Mihon', () {
      final t = DateTime(2026, 10, 1);
      final fetched = DateTime(2026, 9, 1);
      MihonChapter ch(String url, double n, {bool read = true}) =>
          MihonChapter(url: url, number: n, read: read, fetched: fetched);
      final manga = MihonManga(
        sourceId: 1,
        url: '/manga/a/',
        title: 'A',
        chapters: [
          ch('/1', 1),
          ch('/2', 2),
          ch('/2b', 2, read: false),
          ch('/3', 3, read: false),
          ch('/4', 4),
          ch('/5', 5),
          ch('/6', 6, read: false),
          ch('/x', -1),
        ],
        history: {'/4': t, '/1': t.subtract(const Duration(days: 10))},
      );

      final list = importChapters(manga, DateTime(2026, 10, 25));

      expect(list.map((c) => c.number), ['6', '5', '4', '3', '2', '1']);
      expect(
        {for (final c in list) c.number: ?c.readDate},
        {
          // Newer than the newest chapter in the history: right after it.
          '5': t.add(const Duration(milliseconds: 1)),
          '4': t,
          // No history: right before the next newer read chapter.
          '2': t.subtract(const Duration(milliseconds: 1)),
          '1': t.subtract(const Duration(days: 10)),
        },
      );

      // No history at all: counted from when the newest was fetched.
      final plain = importChapters(
        MihonManga(
          sourceId: 1,
          url: '/manga/b/',
          title: 'B',
          chapters: [ch('/1', 1), ch('/2', 2), ch('/3', 3, read: false)],
        ),
        DateTime(2026, 10, 25),
      );
      expect(plain.map((c) => c.readDate), [
        null,
        fetched,
        fetched.subtract(const Duration(milliseconds: 1)),
      ]);
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

    test('ApplyPendingReads keeps progress imported meanwhile', () async {
      final meanwhile = _ImportingMeanwhile();
      await meanwhile.save({'comix:a': PendingRead.upTo('1')});
      final details = sampleComicDetails.copyWith(
        chapters: const [
          Chapter(number: '2', slug: 'comix:a/2', date: '-'),
          Chapter(number: '1', slug: 'comix:a/1', date: '-'),
        ],
      );

      await ApplyPendingReads(meanwhile, history, clock)((
        key: 'comix:a',
        details: details,
      ));

      expect(meanwhile.values['comix:a'], PendingRead.upTo('9'));
    });

    test('removeIfUnchanged removes only what was read', () async {
      final repo = PendingReadRepositoryImpl(
        await Hive.openBox<String>(HiveBoxes.pendingReads),
      );
      await repo.save({'a': PendingRead.upTo('3')});

      await repo.removeIfUnchanged('a', PendingRead.upTo('2'));
      expect(
        (await repo.pendingOf('a')).getOrElse((_) => null),
        PendingRead.upTo('3'),
      );

      await repo.removeIfUnchanged('a', PendingRead.upTo('3'));
      expect((await repo.pendingOf('a')).getOrElse((_) => null), isNull);
    });

    test('MigrateComic moves pending progress to the new key', () async {
      final d5 = DateTime(2026, 10, 5);
      await pending.save({
        'comix:old': PendingRead.upTo('3'),
        'comix:new': PendingRead(chapters: {'5': d5}),
      });
      await bookmarks.saveBookmarks([
        Bookmark(
          slug: 'comix:old',
          comicDetails: sampleComicDetails,
          updatedDate: DateTime(2020),
        ),
      ]);

      await MigrateComic(bookmarks, history, categories, clock, pending)((
        from: 'comix:old',
        to: 'comix:new',
        details: sampleComicDetails,
      ));

      expect(pending.values.keys, ['comix:new']);
      expect(
        pending.values['comix:new'],
        PendingRead(upTo: '3', chapters: {'5': d5}),
      );
    });

    test('ImportLibrary adds placeholders in order, skips existing', () async {
      await bookmarks.saveBookmarks([
        Bookmark(
          slug: 'comix:old',
          comicDetails: sampleComicDetails,
          updatedDate: DateTime(2020),
        ),
      ]);

      final result =
          await ImportLibrary(bookmarks, categories, pending, history, clock)(
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
      expect(pending.values, {'comix:old': PendingRead.upTo('3')});

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
            await ImportLibrary(bookmarks, categories, pending, history, clock)(
              const [
                ImportEntry(
                  key: 'westmanga:oreaku',
                  title: 'OreAku Ore wa',
                  lastRead: '48',
                ),
                ImportEntry(key: 'comix:x', title: 'X', lastRead: '3'),
                ImportEntry(key: 'mangafire:x', title: 'x!', lastRead: '9'),
              ],
            );

        final r = result.getOrElse((f) => fail('$f'));
        expect((r.added, r.existing, r.sameTitle), (1, 0, 2));
        final keys = (await bookmarks.getBookmarks())
            .getOrElse((_) => const [])
            .map((b) => b.slug)
            .toSet();
        expect(keys, {'voratoon:oreaku', 'comix:x'});
        // Progress goes to the bookmark the series lives under, highest wins.
        expect(pending.values, {
          'voratoon:oreaku': PendingRead.upTo('48'),
          'comix:x': PendingRead.upTo('9'),
        });
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
      await pending.save({'comix:a': PendingRead.upTo('7')});
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

    group('Mihon chapters', () {
      const westId = 77;
      final t = DateTime(2026, 10, 20, 8);

      /// A: 3 read, 2 and 1.5 not, 1 read (in the history at [t]).
      /// B: 2 read (in the history an hour later), 1 read without history.
      List<ImportEntry> plan() {
        final source = _Proto()
          ..string(1, 'West Manga')
          ..int64(2, westId);
        final backup = _Proto()
          ..bytes(
            1,
            manga(
              westId,
              '/manga/a/',
              'A',
              fullChapters: [
                backupChapter(
                  '/a/3',
                  3,
                  read: true,
                  uploaded: DateTime(2026, 10, 24),
                ),
                backupChapter('/a/2', 2),
                backupChapter('/a/1.5', 1.5),
                backupChapter('/a/1', 1, read: true),
              ],
              history: [('/a/1', t)],
            ),
          )
          ..bytes(
            1,
            manga(
              westId,
              '/manga/b/',
              'B',
              fullChapters: [
                backupChapter('/b/2', 2, read: true),
                backupChapter('/b/1', 1, read: true),
              ],
              history: [('/b/2', t.add(const Duration(hours: 1)))],
            ),
          )
          ..bytes(101, source.value);
        return planMihonImport(parseMihonBackup(gzip.encode(backup.value)), [
          westmanga,
        ], now: clock.value).single.entries;
      }

      Future<List<ReadHistory>> readHistory() async =>
          (await history.getHistory()).getOrElse((_) => const []);

      Future<Map<String, Bookmark>> library() async => {
        for (final b in (await bookmarks.getBookmarks()).getOrElse(
          (_) => const [],
        ))
          b.slug: b,
      };

      test(
        'placeholders get the chapter list and the exact read set',
        () async {
          final result = await ImportLibrary(
            bookmarks,
            categories,
            pending,
            history,
            clock,
          )(plan());

          final r = result.getOrElse((f) => fail('$f'));
          expect((r.added, r.chaptersRead), (2, 4));
          final a = (await library())['westmanga:a']!;
          expect(a.comicDetails.isPlaceholder, isTrue);
          expect(
            a.comicDetails.chapters.map((c) => (c.number, c.slug, c.date)),
            [
              ('3', 'westmanga:a/3', '1 day ago'),
              ('2', 'westmanga:a/2', '-'),
              ('1.5', 'westmanga:a/1.5', '-'),
              ('1', 'westmanga:a/1', '-'),
            ],
          );

          final read = await readHistory();
          // 2 and 1.5 stay unread: a gap, not "everything up to 3".
          expect(read.map((h) => (h.slug, h.page)).toSet(), {
            ('westmanga:a/3', null),
            ('westmanga:a/1', null),
            ('westmanga:b/2', null),
            ('westmanga:b/1', null),
          });
          expect(pending.values, isEmpty);
          // Comics order by their last read in Mihon; within one, the newest
          // read chapter is the latest.
          final index = HistoryIndex(read);
          expect(index.perComic.map((c) => c.latestHistory.slug), [
            'westmanga:b/2',
            'westmanga:a/3',
          ]);
          expect(
            index.chapter('westmanga:a/3')!.readDate,
            t.add(const Duration(milliseconds: 1)),
          );
          expect(index.chapter('westmanga:a/1')!.readDate, t);
          expect(
            index.chapter('westmanga:b/1')!.readDate,
            t.add(const Duration(hours: 1) - const Duration(milliseconds: 1)),
          );

          // Loading the comic swaps in the source's list; the history stays
          // and gets the loaded details (the cover).
          final loaded = sampleComicDetails.copyWith(
            title: 'A',
            totalChapter: '4',
            chapters: [
              for (final n in ['3', '2', '1.5', '1'])
                Chapter(number: n, slug: 'westmanga:a/$n', date: '-'),
            ],
          );
          await CompleteImportedComic(
            bookmarks,
            ApplyPendingReads(pending, history, clock),
            clock,
          )((key: 'westmanga:a', details: loaded));
          expect((await library())['westmanga:a']!.comicDetails, loaded);
          final after = HistoryIndex(await readHistory());
          expect(after.countOf('westmanga:a'), 2);
          expect(
            after.latestOf('westmanga:a')!.comicDetails.coverImg,
            sampleComicDetails.coverImg,
          );
        },
      );

      test('re-import fills placeholders and never unreads', () async {
        final loaded = sampleComicDetails.copyWith(
          title: 'B',
          totalChapter: '3',
          chapters: [
            for (final n in ['3', '2', '1'])
              Chapter(number: n, slug: 'westmanga:b/$n', date: '-'),
          ],
        );
        await bookmarks.saveBookmarks([
          // Imported by an older version: no chapters.
          Bookmark(
            slug: 'westmanga:a',
            comicDetails: placeholderDetails('westmanga:a', 'A'),
            updatedDate: DateTime(2025),
            addedDate: DateTime(2025),
          ),
          Bookmark(
            slug: 'westmanga:b',
            comicDetails: loaded,
            updatedDate: DateTime(2024),
          ),
        ]);
        final later = t.add(const Duration(hours: 2));
        await history.saveHistory([
          // Read here only.
          ReadHistory(
            slug: 'westmanga:b/3',
            chapterNumber: '3',
            readDate: DateTime(2026, 10, 22),
            comicDetails: loaded,
            comicSlug: 'westmanga:b',
          ),
          // Half read here after Mihon.
          ReadHistory(
            slug: 'westmanga:a/1',
            chapterNumber: '1',
            readDate: later,
            comicDetails: placeholderDetails('westmanga:a', 'A'),
            comicSlug: 'westmanga:a',
            page: 2,
            pageCount: 20,
          ),
        ]);
        final import = ImportLibrary(
          bookmarks,
          categories,
          pending,
          history,
          clock,
        );

        final first = (await import(plan())).getOrElse((f) => fail('$f'));
        final second = (await import(plan())).getOrElse((f) => fail('$f'));

        expect((first.added, first.existing, first.chaptersRead), (0, 2, 4));
        expect((second.added, second.existing, second.chaptersRead), (0, 2, 0));
        final saved = await library();
        expect(saved.keys, unorderedEquals(['westmanga:a', 'westmanga:b']));
        final a = saved['westmanga:a']!;
        expect(a.comicDetails.chapters.map((c) => c.number), [
          '3',
          '2',
          '1.5',
          '1',
        ]);
        expect((a.updatedDate, a.addedDate), (DateTime(2025), DateTime(2025)));
        // A loaded list is not replaced by the backup's.
        expect(saved['westmanga:b']!.comicDetails, loaded);

        final read = HistoryIndex(await readHistory());
        expect(read.isFinished('westmanga:b/3'), isTrue);
        expect(read.isFinished('westmanga:b/2'), isTrue);
        expect(read.isFinished('westmanga:a/3'), isTrue);
        // Finished, keeping the later date from here.
        expect(read.chapter('westmanga:a/1')!.isFinished, isTrue);
        expect(read.chapter('westmanga:a/1')!.readDate, later);
        expect(read.containsChapter('westmanga:a/2'), isFalse);
      });

      test('read chapters missing from the list wait', () async {
        // B is bookmarked from another source with a shorter list.
        final other = sampleComicDetails.copyWith(
          title: 'B',
          chapters: const [Chapter(number: '1', slug: 'comix:b/1', date: '-')],
        );
        await bookmarks.saveBookmarks([
          Bookmark(slug: 'comix:b', comicDetails: other, updatedDate: t),
        ]);
        await pending.save({'comix:b': PendingRead.upTo('0.5')});

        await ImportLibrary(bookmarks, categories, pending, history, clock)(
          plan().where((e) => e.title == 'B').toList(),
        );

        final read = await readHistory();
        expect(read.map((h) => h.slug), ['comix:b/1']);
        expect(pending.values, {
          'comix:b': PendingRead(
            upTo: '0.5',
            chapters: {'2': t.add(const Duration(hours: 1))},
          ),
        });
      });
    });

    test(
      'pending reads: the old format still works, the new is exact',
      () async {
        final box = await Hive.openBox<String>(HiveBoxes.pendingReads);
        // Stored by an older version: the highest chapter read.
        await box.put('comix:old', '2');
        final repo = PendingReadRepositoryImpl(box);
        expect(
          (await repo.pendingOf('comix:old')).getOrElse((_) => null),
          PendingRead.upTo('2'),
        );
        final d9 = DateTime(2026, 10, 3);
        final d7 = DateTime(2026, 10, 1);
        final exact = PendingRead(chapters: {'9': d9, '7': d7});
        await repo.save({'comix:new': exact});
        expect(
          (await repo.pendingOf('comix:new')).getOrElse((_) => null),
          exact,
        );

        ComicDetails details(String key, List<String> numbers) =>
            sampleComicDetails.copyWith(
              chapters: [
                for (final n in numbers)
                  Chapter(number: n, slug: '$key/$n', date: '-'),
              ],
            );
        final apply = ApplyPendingReads(repo, history, clock);
        await apply((
          key: 'comix:old',
          details: details('comix:old', ['3', '2', '1']),
        ));
        await apply((
          key: 'comix:new',
          details: details('comix:new', ['9', '8', '7.0']),
        ));

        final read = HistoryIndex(
          (await history.getHistory()).getOrElse((_) => const []),
        );
        expect(read.containsChapter('comix:old/2'), isTrue);
        expect(read.containsChapter('comix:old/1'), isTrue);
        expect(read.containsChapter('comix:old/3'), isFalse);
        expect(read.chapter('comix:new/9')!.readDate, d9);
        expect(read.chapter('comix:new/7.0')!.readDate, d7);
        expect(read.containsChapter('comix:new/8'), isFalse);
        expect(box.isEmpty, isTrue);
      },
    );

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
          clock,
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
