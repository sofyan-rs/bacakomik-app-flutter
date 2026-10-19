import 'package:bacakomik_app/core/data/datasources/series_remote_data_source.dart';
import 'package:bacakomik_app/core/error/exceptions.dart';
import 'package:bacakomik_app/core/error/failures.dart';
import 'package:bacakomik_app/features/comic_detail/data/repositories/comic_detail_repository_impl.dart';
import 'package:bacakomik_app/features/reader/data/repositories/reader_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../fixtures/api_fixtures.dart';
import '../helpers/mocks.dart';

void main() {
  late MockApiClient client;
  late SeriesRemoteDataSource remote;
  late FakeNetworkInfo network;

  setUp(() {
    client = MockApiClient();
    remote = SeriesRemoteDataSourceImpl(client);
    network = FakeNetworkInfo();
  });

  group('ComicDetailRepositoryImpl', () {
    test('maps series and chapters', () async {
      when(() => client.get('/series/solo-leveling'))
          .thenAnswer((_) async => {'data': seriesDetail});
      when(() => client.get('/series/solo-leveling/chapters'))
          .thenAnswer((_) async => {'data': chapterList});

      final result = await ComicDetailRepositoryImpl(remote, network)
          .getComicDetails('solo-leveling');
      final details = result.getOrElse((f) => throw f);

      expect(details.alternativeTitle, '-');
      expect(details.status, 'Completed');
      expect(details.type, 'Manhwa');
      expect(details.rating, '9');
      expect(details.synopsis, 'Hunter story.');
      expect(details.totalChapter, '2');
      expect(details.genres.map((g) => g.slug), ['1', '7']);
      expect(
        details.chapters.map((c) => c.slug),
        ['solo-leveling/2', 'solo-leveling/1.5'],
      );
      expect(details.chapters.first.date, '-');
    });

    test('either request failing gives ServerFailure', () async {
      when(() => client.get('/series/x'))
          .thenAnswer((_) async => {'data': seriesDetail});
      when(() => client.get('/series/x/chapters'))
          .thenThrow(const ServerException('not found', statusCode: 404));

      final result =
          await ComicDetailRepositoryImpl(remote, network).getComicDetails('x');

      expect(result.getLeft().toNullable()?.message, 'not found');
    });
  });

  group('ReaderRepositoryImpl', () {
    test('splits chapter slug and builds prev/next slugs', () async {
      when(() => client.get('/series/solo-leveling/chapters/2'))
          .thenAnswer((_) async => {'data': chapterDetail});

      final result = await ReaderRepositoryImpl(remote, network)
          .getChapter('solo-leveling/2');
      final chapter = result.getOrElse((f) => throw f);

      expect(chapter.chapterTitle, 'Chapter 2');
      expect(chapter.chapterNumber, '2');
      expect(chapter.seriesSlug, 'solo-leveling');
      expect(chapter.previousChapterSlug, 'solo-leveling/1.5');
      expect(chapter.nextChapterSlug, isNull);
      expect(chapter.images, hasLength(2));
    });

    test('rejects slug without series part', () async {
      final result = await ReaderRepositoryImpl(remote, network).getChapter('2');

      expect(result.getLeft().toNullable(), isA<ServerFailure>());
      verifyZeroInteractions(client);
    });
  });
}
