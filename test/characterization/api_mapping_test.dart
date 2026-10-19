import 'package:bacakomik_app/data/data_provider/bacakomik_data_provider.dart';
import 'package:bacakomik_app/data/repository/chapter_read_repository.dart';
import 'package:bacakomik_app/data/repository/comic_details_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../fixtures/api_fixtures.dart';

class MockDataProvider extends Mock implements BacaKomikDataProvider {}

void main() {
  late MockDataProvider provider;

  setUp(() => provider = MockDataProvider());

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
