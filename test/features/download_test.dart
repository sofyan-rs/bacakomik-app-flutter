import 'package:bacakomik_app/core/domain/entities/comic_details.dart';
import 'package:bacakomik_app/core/error/failures.dart';
import 'package:bacakomik_app/core/storage/hive_boxes.dart';
import 'package:bacakomik_app/core/utils/clock.dart';
import 'package:bacakomik_app/core/utils/utils.dart';
import 'package:bacakomik_app/features/bookmark/domain/entities/bookmark.dart';
import 'package:bacakomik_app/features/bookmark/domain/repositories/bookmark_repository.dart';
import 'package:bacakomik_app/features/comic_detail/domain/repositories/comic_detail_repository.dart';
import 'package:bacakomik_app/features/comic_detail/domain/usecases/get_comic_details.dart';
import 'package:bacakomik_app/features/download/data/datasources/download_file_data_source.dart';
import 'package:bacakomik_app/features/download/data/datasources/download_local_data_source.dart';
import 'package:bacakomik_app/features/download/data/models/downloaded_chapter_model.dart';
import 'package:bacakomik_app/features/download/data/repositories/download_repository_impl.dart';
import 'package:bacakomik_app/features/download/domain/entities/download_library.dart';
import 'package:bacakomik_app/features/download/domain/entities/downloaded_chapter.dart';
import 'package:bacakomik_app/features/history/domain/entities/read_history.dart';
import 'package:bacakomik_app/features/history/domain/repositories/history_repository.dart';
import 'package:bacakomik_app/features/reader/domain/entities/chapter_content.dart';
import 'package:bacakomik_app/features/reader/domain/repositories/reader_repository.dart';
import 'package:bacakomik_app/features/reader/domain/usecases/get_chapter_content.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hive_ce/hive.dart';

import '../fixtures/library_fixtures.dart';
import '../helpers/hive.dart';

const details = sampleComicDetails;

class FixedClock implements Clock {
  @override
  DateTime now() => DateTime.fromMillisecondsSinceEpoch(1000);
}

/// Files kept in memory. URLs in [failing] throw.
class FakeFiles implements DownloadFileDataSource {
  final files = <String, int>{};
  final failing = <String>{};
  final requested = <String>[];

  @override
  String comicDir(String comicSlug) => comicSlug;

  @override
  String chapterDir(String comicSlug, String chapterNumber) =>
      '$comicSlug/$chapterNumber';

  @override
  Future<({String path, int size})> download(
    String url,
    String pathWithoutExtension, {
    CancelToken? cancelToken,
  }) async {
    requested.add(url);
    await Future<void>.delayed(Duration.zero);
    if (failing.contains(url)) throw Exception('404 $url');
    final path = '$pathWithoutExtension.jpg';
    files[path] = 10;
    return (path: path, size: 10);
  }

  @override
  Future<String> absolute(String path) async => '/root/$path';

  @override
  Future<bool> exists(String path) async => files.containsKey(path);

  @override
  Future<void> delete(String path) async =>
      files.removeWhere((key, _) => key == path || key.startsWith('$path/'));

  @override
  Future<void> deleteAll() async => files.clear();
}

/// Chapters of [details] with three pages each.
class FakeReader implements ReaderRepository {
  final requested = <String>[];

  @override
  Future<Either<Failure, ChapterContent>> getChapter(String slug) async {
    requested.add(slug);
    final number = slug.split('/').last;
    return right(
      ChapterContent(
        chapterTitle: 'Chapter $number',
        chapterNumber: number,
        seriesSlug: 'solo-leveling',
        images: [for (var i = 0; i < 3; i++) 'https://img/$number/$i.jpg'],
      ),
    );
  }
}

class FakeComicDetailRepository implements ComicDetailRepository {
  Either<Failure, ComicDetails> result = left(const NetworkFailure());

  @override
  Future<Either<Failure, ComicDetails>> getComicDetails(String slug) async =>
      result;
}

class FakeBookmarks implements BookmarkRepository {
  List<Bookmark> bookmarks = [];

  @override
  Future<Either<Failure, List<Bookmark>>> getBookmarks() async =>
      right(bookmarks);

  @override
  Future<Either<Failure, Unit>> saveBookmarks(List<Bookmark> b) async =>
      right(unit);

  @override
  Future<Either<Failure, Unit>> removeBookmarks(List<String> s) async =>
      right(unit);
}

class FakeHistory implements HistoryRepository {
  List<ReadHistory> history = [];

  @override
  Future<Either<Failure, List<ReadHistory>>> getHistory() async =>
      right(history);

  @override
  Future<Either<Failure, Unit>> saveHistory(List<ReadHistory> h) async =>
      right(unit);

  @override
  Future<Either<Failure, Unit>> removeHistory(List<String> s) async =>
      right(unit);

  @override
  Future<Either<Failure, Unit>> removeComicHistory(String s) async =>
      right(unit);

  @override
  Future<Either<Failure, Unit>> clearHistory() async => right(unit);
}

void main() {
  late Future<void> Function() tearDownHive;
  late DownloadLocalDataSource local;
  late FakeFiles files;
  late FakeReader reader;
  late DownloadRepositoryImpl repo;

  Future<DownloadLibrary> library() async =>
      (await repo.getDownloads()).getOrElse((f) => throw f);

  /// Waits until nothing is queued or downloading.
  Future<void> settle() async {
    for (var i = 0; i < 1000; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
      final busy = local.getChapters().any(
        (c) =>
            c.status == DownloadStatus.queued ||
            c.status == DownloadStatus.downloading,
      );
      if (!busy) return;
    }
    fail('Downloads did not settle');
  }

  Future<void> enqueue(List<Chapter> chapters) async {
    await repo.enqueue(
      comicSlug: 'solo-leveling',
      comicDetails: details,
      chapters: chapters,
    );
    await settle();
  }

  setUp(() async {
    tearDownHive = await setUpTempHive();
    local = DownloadLocalDataSourceImpl(
      await Hive.openBox<String>(HiveBoxes.downloads),
      await Hive.openBox<String>(HiveBoxes.downloadComics),
    );
    files = FakeFiles();
    reader = FakeReader();
    repo = DownloadRepositoryImpl(local, files, reader, FixedClock());
  });

  tearDown(() => tearDownHive());

  group('DownloadRepositoryImpl', () {
    test('downloads every page in order, with the cover', () async {
      await enqueue([details.chapters.last]);

      final chapter = local.getChapter('solo-leveling/1')!;
      expect(chapter.status, DownloadStatus.completed);
      expect(chapter.pages, [
        'solo-leveling/1/000.jpg',
        'solo-leveling/1/001.jpg',
        'solo-leveling/1/002.jpg',
      ]);
      expect(chapter.pageCount, 3);
      expect(chapter.sizeBytes, 30);
      expect(chapter.downloadedAt, isNotNull);
      expect(local.getComic('solo-leveling')!.cover, 'solo-leveling/cover.jpg');
    });

    test('runs chapters one at a time in the given order', () async {
      await enqueue(details.chapters.reversed.toList());

      expect(reader.requested, ['solo-leveling/1', 'solo-leveling/2']);
      final downloads = await library();
      expect(downloads.completedCount, 2);
    });

    test('skips chapters that are already downloaded', () async {
      await enqueue([details.chapters.last]);
      await enqueue([details.chapters.last]);

      expect(reader.requested, ['solo-leveling/1']);
    });

    test('offline chapter has file paths and neighbours', () async {
      await enqueue([details.chapters.last]);

      final content = await repo.getOfflineChapter('solo-leveling/1');

      expect(content?.isOffline, isTrue);
      expect(content?.chapterTitle, 'Chapter 1');
      expect(content?.images.first, '/root/solo-leveling/1/000.jpg');
      expect(await repo.getOfflineChapter('solo-leveling/2'), isNull);
    });

    test('offline chapter with a missing file is not readable', () async {
      await enqueue([details.chapters.last]);
      files.files.remove('solo-leveling/1/001.jpg');

      expect(await repo.getOfflineChapter('solo-leveling/1'), isNull);
    });

    test(
      'a failing page fails the chapter; retry fetches only the rest',
      () async {
        files.failing.add('https://img/1/1.jpg');
        await enqueue([details.chapters.last]);

        var chapter = local.getChapter('solo-leveling/1')!;
        expect(chapter.status, DownloadStatus.failed);
        expect(chapter.pages, [
          'solo-leveling/1/000.jpg',
          'solo-leveling/1/002.jpg',
        ]);

        files.failing.clear();
        files.requested.clear();
        await repo.retry(['solo-leveling/1']);
        await settle();

        chapter = local.getChapter('solo-leveling/1')!;
        expect(chapter.status, DownloadStatus.completed);
        expect(chapter.pages, hasLength(3));
        expect(files.requested, ['https://img/1/1.jpg']);
      },
      timeout: const Timeout(Duration(seconds: 20)),
    );

    test('downloads cut off by a restart become failed', () async {
      await local.putChapters([
        DownloadedChapterModel(
          slug: 'solo-leveling/2',
          comicSlug: 'solo-leveling',
          chapterNumber: '2',
          addedAt: DateTime.fromMillisecondsSinceEpoch(0),
          status: DownloadStatus.downloading,
        ),
      ]);

      final downloads = await library();

      expect(
        downloads.chapter('solo-leveling/2')?.status,
        DownloadStatus.failed,
      );
    });

    test('delete removes files, record and the unused comic', () async {
      await enqueue([details.chapters.last]);

      await repo.delete(['solo-leveling/1']);

      expect(local.getChapters(), isEmpty);
      expect(local.getComics(), isEmpty);
      expect(files.files, isEmpty);
    });

    test('clear removes everything', () async {
      await enqueue(details.chapters);

      await repo.clear();

      expect((await library()).chapters, isEmpty);
      expect(files.files, isEmpty);
    });
  });

  group('use cases', () {
    test('GetChapterContent reads a downloaded chapter offline', () async {
      await enqueue([details.chapters.last]);
      final getChapter = GetChapterContent(reader, repo);
      reader.requested.clear();

      final offline = (await getChapter(
        'solo-leveling/1',
      )).getOrElse((f) => throw f);
      final online = (await getChapter(
        'solo-leveling/2',
      )).getOrElse((f) => throw f);

      expect(offline.isOffline, isTrue);
      expect(online.isOffline, isFalse);
      expect(reader.requested, ['solo-leveling/2']);
    });

    group('GetComicDetails', () {
      late FakeComicDetailRepository comics;
      late FakeBookmarks bookmarks;
      late FakeHistory history;
      late GetComicDetails getDetails;

      String title(Either<Failure, ComicDetails> result) =>
          result.getOrElse((f) => throw f).title;

      setUp(() {
        comics = FakeComicDetailRepository();
        bookmarks = FakeBookmarks();
        history = FakeHistory();
        getDetails = GetComicDetails(comics, repo, bookmarks, history);
      });

      test('fails offline for a comic outside the library', () async {
        final result = await getDetails('solo-leveling');

        expect(result.getLeft().toNullable(), isA<NetworkFailure>());
      });

      test('online result wins over stored copies', () async {
        comics.result = right(details.copyWith(title: 'Online'));
        bookmarks.bookmarks = [
          Bookmark(
            slug: 'solo-leveling',
            comicDetails: details.copyWith(title: 'Bookmark'),
            updatedDate: DateTime(2026),
          ),
        ];

        expect(title(await getDetails('solo-leveling')), 'Online');
      });

      test('falls back to downloads, then bookmarks, then history', () async {
        history.history = [
          ReadHistory(
            slug: 'solo-leveling/1',
            chapterNumber: '1',
            readDate: DateTime(2026),
            comicDetails: details.copyWith(title: 'History'),
            comicSlug: 'solo-leveling',
          ),
        ];
        expect(title(await getDetails('solo-leveling')), 'History');

        bookmarks.bookmarks = [
          Bookmark(
            slug: 'solo-leveling',
            comicDetails: details.copyWith(title: 'Bookmark'),
            updatedDate: DateTime(2026),
          ),
        ];
        expect(title(await getDetails('solo-leveling')), 'Bookmark');

        await enqueue([details.chapters.last]);
        expect(title(await getDetails('solo-leveling')), details.title);
      });
    });
  });

  group('DownloadLibrary', () {
    DownloadedChapter chapter(
      String slug,
      DownloadStatus status,
      int addedAt, {
      int size = 0,
    }) => DownloadedChapter(
      slug: slug,
      comicSlug: slug.split('/').first,
      chapterNumber: slug.split('/').last,
      status: status,
      addedAt: DateTime.fromMillisecondsSinceEpoch(addedAt),
      sizeBytes: size,
    );

    DownloadedComic comic(String slug, String title) => DownloadedComic(
      slug: slug,
      comicDetails: details.copyWith(title: title),
    );

    final library = DownloadLibrary(
      chapters: {
        for (final c in [
          chapter('b/10', DownloadStatus.completed, 1, size: 5),
          chapter('b/9.5', DownloadStatus.completed, 2, size: 5),
          chapter('a/1', DownloadStatus.completed, 3, size: 5),
          chapter('a/3', DownloadStatus.failed, 5),
          chapter('a/2', DownloadStatus.queued, 4),
        ])
          c.slug: c,
      },
      comics: {'a': comic('a', 'Alpha'), 'b': comic('b', 'beta')},
    );

    test('pending is in queue order', () {
      expect(library.pending.map((c) => c.slug), ['a/2', 'a/3']);
    });

    test('completed chapters by comic title, then by number', () {
      final groups = library.completedByComic;
      expect(groups.map((g) => g.$1.slug), ['a', 'b']);
      expect(groups.last.$2.map((c) => c.slug), ['b/9.5', 'b/10']);
    });

    test('counts and size', () {
      expect(library.completedCount, 3);
      expect(library.totalBytes, 15);
    });
  });

  test('formatBytes', () {
    expect(formatBytes(512), '512 B');
    expect(formatBytes(2048), '2 KB');
    expect(formatBytes(1536 * 1024), '1.5 MB');
    expect(formatBytes(40 * 1024 * 1024), '40 MB');
  });
}
