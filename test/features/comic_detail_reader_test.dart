import 'package:bacakomik_app/core/data/datasources/series_remote_data_source.dart';
import 'package:bacakomik_app/core/error/exceptions.dart';
import 'package:bacakomik_app/core/error/failures.dart';
import 'package:bacakomik_app/features/comic_detail/data/repositories/comic_detail_repository_impl.dart';
import 'package:bacakomik_app/features/reader/data/repositories/reader_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fixtures/api_fixtures.dart';
import '../helpers/fake_source.dart';
import '../helpers/mocks.dart';

void main() {
  late FakeSourceBackend bacakomik;
  late FakeSourceBackend voratoon;
  late FakeSourceRegistry sources;
  late SeriesRemoteDataSource remote;
  late FakeNetworkInfo network;

  setUp(() {
    bacakomik = FakeSourceBackend();
    voratoon = FakeSourceBackend();
    sources = FakeSourceRegistry({
      'bacakomik': bacakomik,
      'voratoon': voratoon,
    });
    remote = SeriesRemoteDataSourceImpl(sources);
    network = FakeNetworkInfo();
  });

  group('ComicDetailRepositoryImpl', () {
    test('maps series and chapters', () async {
      bacakomik.responses
        ..['series'] = seriesDetail
        ..['chapters'] = chapterList;

      final result = await ComicDetailRepositoryImpl(
        remote,
        network,
      ).getComicDetails('solo-leveling');
      final details = result.getOrElse((f) => throw f);

      expect(details.alternativeTitle, '-');
      expect(details.status, 'Completed');
      expect(details.type, 'Manhwa');
      expect(details.rating, '9');
      expect(details.synopsis, 'Hunter story.');
      expect(details.totalChapter, '2');
      expect(details.genres.map((g) => g.slug), ['1', '7']);
      expect(details.chapters.map((c) => c.slug), [
        'solo-leveling/2',
        'solo-leveling/1.5',
      ]);
      expect(details.chapters.first.date, '-');
      expect(details.source, 'bacakomik');
      expect(bacakomik.argsOf('series'), ['solo-leveling']);
      expect(bacakomik.argsOf('chapters'), ['solo-leveling']);
    });

    test('prefixed key calls its source with the bare slug', () async {
      voratoon.responses
        ..['series'] = seriesDetail
        ..['chapters'] = chapterList;

      final details = (await ComicDetailRepositoryImpl(
        remote,
        network,
      ).getComicDetails('voratoon:solo-leveling')).getOrElse((f) => throw f);

      expect(details.source, 'voratoon');
      expect(details.chapters.map((c) => c.slug), [
        'voratoon:solo-leveling/2',
        'voratoon:solo-leveling/1.5',
      ]);
      expect(voratoon.argsOf('series'), ['solo-leveling']);
      expect(bacakomik.calls, isEmpty);
    });

    test('chapters only, then series with those chapters', () async {
      bacakomik.responses
        ..['series'] = seriesDetail
        ..['chapters'] = chapterList;
      final repo = ComicDetailRepositoryImpl(remote, network);

      final chapters = (await repo.getChapters('solo-leveling'))
          .getOrElse((f) => throw f);
      expect(bacakomik.calls.map((c) => c.method), ['chapters']);
      expect(chapters.map((c) => c.slug), [
        'solo-leveling/2',
        'solo-leveling/1.5',
      ]);

      final details = (await repo.getSeries(
        'solo-leveling',
        chapters,
      )).getOrElse((f) => throw f);
      final both = (await repo.getComicDetails('solo-leveling'))
          .getOrElse((f) => throw f);
      expect(details, both);
    });

    test('either request failing gives ServerFailure', () async {
      bacakomik.responses
        ..['series'] = seriesDetail
        ..['chapters'] = const ServerException('not found', statusCode: 404);

      final result = await ComicDetailRepositoryImpl(
        remote,
        network,
      ).getComicDetails('x');

      expect(result.getLeft().toNullable()?.message, 'not found');
    });

    test('unexpected response shape gives ServerFailure', () async {
      bacakomik.responses
        ..['series'] = 'nope'
        ..['chapters'] = chapterList;

      final result = await ComicDetailRepositoryImpl(
        remote,
        network,
      ).getComicDetails('x');

      expect(result.getLeft().toNullable(), isA<ServerFailure>());
    });
  });

  group('ReaderRepositoryImpl', () {
    test('splits chapter slug and builds prev/next slugs', () async {
      bacakomik.responses['chapter'] = chapterDetail;

      final result = await ReaderRepositoryImpl(
        remote,
        network,
      ).getChapter('solo-leveling/2');
      final chapter = result.getOrElse((f) => throw f);

      expect(chapter.chapterTitle, 'Chapter 2');
      expect(chapter.chapterNumber, '2');
      expect(chapter.seriesSlug, 'solo-leveling');
      expect(chapter.previousChapterSlug, 'solo-leveling/1.5');
      expect(chapter.nextChapterSlug, isNull);
      expect(chapter.images, hasLength(2));
      expect(bacakomik.argsOf('chapter'), ['solo-leveling', 2]);
    });

    test('prefixed chapter slug keeps the key in prev/next', () async {
      voratoon.responses['chapter'] = chapterDetail;

      final chapter = (await ReaderRepositoryImpl(
        remote,
        network,
      ).getChapter('voratoon:solo-leveling/2')).getOrElse((f) => throw f);

      expect(chapter.seriesSlug, 'voratoon:solo-leveling');
      expect(chapter.previousChapterSlug, 'voratoon:solo-leveling/1.5');
      expect(voratoon.argsOf('chapter'), ['solo-leveling', 2]);
    });

    test('a chapter without pages is a failure', () async {
      bacakomik.responses['chapter'] = {...chapterDetail, 'images': <String>[]};

      final result = await ReaderRepositoryImpl(
        remote,
        network,
      ).getChapter('solo-leveling/2');

      expect(
        result.getLeft().toNullable(),
        isA<ServerFailure>().having(
          (f) => f.message,
          'message',
          ReaderRepositoryImpl.noPages,
        ),
      );
    });

    test('rejects slug without series part', () async {
      final result = await ReaderRepositoryImpl(
        remote,
        network,
      ).getChapter('2');

      expect(result.getLeft().toNullable(), isA<ServerFailure>());
      expect(sources.requested, isEmpty);
    });
  });
}
