import 'package:bacakomik_app/data/data_provider/bacakomik_data_provider.dart';
import 'package:bacakomik_app/data/repository/chapter_read_repository.dart';
import 'package:bacakomik_app/data/repository/comic_details_repository.dart';
import 'package:bacakomik_app/data/repository/explore_data_repository.dart';
import 'package:bacakomik_app/data/repository/latest_repository.dart';
import 'package:bacakomik_app/data/repository/search_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../fixtures/api_fixtures.dart';

class MockDataProvider extends Mock implements BacaKomikDataProvider {}

void main() {
  late MockDataProvider provider;

  setUp(() => provider = MockDataProvider());

  group('list repositories', () {
    test('LatestRepository requests latest sort by page', () async {
      when(() => provider.getSeriesList(sort: 'latest', page: 3))
          .thenAnswer((_) async => listResponse([seriesListItem]));

      final result = await LatestRepository(provider).getLatest(3);

      expect(result.single.completed, isTrue);
      expect(result.single.slug, 'solo-leveling');
    });

    test('SearchRepository passes keyword and page', () async {
      when(() => provider.getSeriesList(query: 'solo', page: 2))
          .thenAnswer((_) async => listResponse([seriesListItem]));

      final result =
          await SearchRepository(provider).getSearchResult('solo', 2);

      expect(result.single.title, 'Solo Leveling');
    });

    test('ExploreRepository drops default/all filters', () async {
      when(() => provider.getSeriesList(
            sort: null,
            status: null,
            format: null,
            genres: ['action'],
            page: 1,
          )).thenAnswer((_) async => listResponse([]));
      when(() => provider.getSeriesList(
            sort: 'rating',
            status: 'completed',
            format: 'manga',
            genres: [],
            page: 2,
          )).thenAnswer((_) async => listResponse([seriesListItem]));

      final repo = ExploreRepository(provider);

      expect(
        await repo.getResult('default', 'all', 'all', ['action'], 1),
        isEmpty,
      );
      expect(
        await repo.getResult('rating', 'completed', 'manga', [], 2),
        hasLength(1),
      );
    });
  });

  group('ComicDetailsRepository', () {
    test('maps series and chapters', () async {
      when(() => provider.getSeries('solo-leveling'))
          .thenAnswer((_) async => {'data': seriesDetail});
      when(() => provider.getChapters('solo-leveling'))
          .thenAnswer((_) async => {'data': chapterList});

      final details = await ComicDetailsRepository(provider)
          .getComicDetails('solo-leveling');

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
  });

  group('ChapterReadRepository', () {
    test('splits chapter slug and builds prev/next slugs', () async {
      when(() => provider.getChapter('solo-leveling', '2'))
          .thenAnswer((_) async => {'data': chapterDetail});

      final chapter = await ChapterReadRepository(provider)
          .getChapterRead('solo-leveling/2');

      expect(chapter.chapterTitle, 'Chapter 2');
      expect(chapter.chapterNumber, '2');
      expect(chapter.seriesSlug, 'solo-leveling');
      expect(chapter.previousChapterSlug, 'solo-leveling/1.5');
      expect(chapter.nextChapterSlug, isNull);
      expect(chapter.imageChapters, hasLength(2));
    });

    test('rejects slug without series part', () {
      expect(
        () => ChapterReadRepository(provider).getChapterRead('2'),
        throwsException,
      );
    });
  });
}
