import 'package:bacakomik_app/core/data/datasources/series_remote_data_source.dart';
import 'package:bacakomik_app/core/data/models/comic_details_model.dart';
import 'package:bacakomik_app/core/domain/entities/comic_details.dart';
import 'package:bacakomik_app/core/error/exceptions.dart';
import 'package:bacakomik_app/core/error/failures.dart';
import 'package:bacakomik_app/core/usecase/usecase.dart';
import 'package:bacakomik_app/core/utils/clock.dart';
import 'package:bacakomik_app/features/bookmark/domain/entities/bookmark.dart';
import 'package:bacakomik_app/features/history/domain/entities/read_history.dart';
import 'package:bacakomik_app/features/sync/data/repositories/series_lookup_repository_impl.dart';
import 'package:bacakomik_app/features/sync/domain/entities/sync_snapshot.dart';
import 'package:bacakomik_app/features/sync/domain/repositories/series_lookup_repository.dart';
import 'package:bacakomik_app/features/sync/domain/repositories/sync_repository.dart';
import 'package:bacakomik_app/features/sync/domain/usecases/migrate_library.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../fixtures/api_fixtures.dart';
import '../fixtures/library_fixtures.dart';
import '../helpers/mocks.dart';

class FixedClock implements Clock {
  FixedClock(this.value);

  final DateTime value;

  @override
  DateTime now() => value;
}

class MockLookup extends Mock implements SeriesLookupRepository {}

class MockSyncRepository extends Mock implements SyncRepository {}

DateTime at(int ms) => DateTime.fromMillisecondsSinceEpoch(ms);

final now = at(1000);
final keepSince = at(0);

const fresh = ComicDetails(
  title: 'Solo Leveling',
  coverImg: 'https://api.example/img/new',
  alternativeTitle: '-',
  released: '2018',
  status: 'Completed',
  totalChapter: '1',
  author: 'Chugong',
  type: 'Manhwa',
  rating: '9',
  synopsis: '',
  genres: [],
  chapters: [Chapter(number: '1', slug: 'solo-leveling-new/1', date: '-')],
  source: ComicSource.current,
);

Bookmark bookmark(String slug, int updated, {ComicDetails? details}) =>
    Bookmark(
      slug: slug,
      comicDetails: details ?? sampleComicDetails,
      updatedDate: at(updated),
    );

ReadHistory read(String slug, int date, {ComicDetails? details, int? page}) =>
    ReadHistory(
      slug: slug,
      chapterNumber: slug.split('/').last,
      readDate: at(date),
      comicDetails: details ?? sampleComicDetails,
      comicSlug: slug.split('/').first,
      page: page,
      pageCount: page == null ? null : 20,
    );

void main() {
  setUpAll(() => registerFallbackValue(sampleComicDetails));

  group('MigrateSnapshot', () {
    late MockLookup lookup;
    late MigrateSnapshot migrate;

    setUp(() {
      lookup = MockLookup();
      migrate = MigrateSnapshot(lookup, FixedClock(now));
    });

    Future<SyncSnapshot> run(SyncSnapshot s) =>
        migrate(s, keepDeletionsSince: keepSince);

    test('moves a renamed comic and keeps read progress', () async {
      when(() => lookup.find('solo', any())).thenAnswer(
        (_) async => right((slug: 'solo-leveling-new', details: fresh)),
      );

      final result = await run(
        SyncSnapshot(
          bookmarks: [bookmark('solo', 5)],
          history: [read('solo/1', 7, page: 3)],
        ),
      );

      final b = result.bookmarks.single;
      expect(b.slug, 'solo-leveling-new');
      expect(b.comicDetails, fresh);
      expect(b.updatedDate, at(5));
      final h = result.history.single;
      expect(h.slug, 'solo-leveling-new/1');
      expect(h.comicSlug, 'solo-leveling-new');
      expect(h.comicDetails, fresh);
      expect((h.readDate, h.page, h.pageCount), (at(7), 3, 20));
      expect(result.deletedBookmarks, {'solo': now});
      expect(result.deletedHistory, {'solo/1': now});
      // One lookup per comic, shared by the bookmark and its history.
      verify(() => lookup.find('solo', any())).called(1);
    });

    test('same slug only refreshes the details, without deletions', () async {
      when(() => lookup.find('solo', any()))
          .thenAnswer((_) async => right((slug: 'solo', details: fresh)));

      final result = await run(SyncSnapshot(bookmarks: [bookmark('solo', 5)]));

      expect(result.bookmarks.single.slug, 'solo');
      expect(result.bookmarks.single.comicDetails.source, ComicSource.current);
      expect(result.deletedBookmarks, isEmpty);
    });

    test('marks a comic missing from the new source as legacy', () async {
      when(() => lookup.find('gone', any()))
          .thenAnswer((_) async => right(null));

      final result = await run(SyncSnapshot(bookmarks: [bookmark('gone', 5)]));

      expect(result.bookmarks.single.slug, 'gone');
      expect(
        result.bookmarks.single.comicDetails,
        sampleComicDetails.copyWith(source: ComicSource.legacy),
      );
    });

    test('stops at the first failure and leaves the rest for later', () async {
      when(() => lookup.find(any(), any()))
          .thenAnswer((_) async => left(const NetworkFailure()));
      final snapshot = SyncSnapshot(
        bookmarks: [bookmark('a', 1), bookmark('b', 1)],
      );

      expect(await run(snapshot), snapshot);
      verify(() => lookup.find(any(), any())).called(1);
    });

    test(
      'skips migrated comics and looks up at most maxComicsPerRun',
      () async {
        when(() => lookup.find(any(), any()))
            .thenAnswer((_) async => right(null));
        final migrated = bookmark('done', 1, details: fresh);

        await run(
          SyncSnapshot(
            bookmarks: [
              migrated,
              for (var i = 0; i < MigrateSnapshot.maxComicsPerRun + 5; i++)
                bookmark('c$i', 1),
            ],
          ),
        );

        verifyNever(() => lookup.find('done', any()));
        verify(() => lookup.find(any(), any()))
            .called(MigrateSnapshot.maxComicsPerRun);
      },
    );

    test('keeps the newest when the new slug is already bookmarked', () async {
      when(() => lookup.find('solo', any())).thenAnswer(
        (_) async => right((slug: 'solo-leveling-new', details: fresh)),
      );

      final result = await run(
        SyncSnapshot(
          bookmarks: [
            bookmark('solo', 9),
            bookmark('solo-leveling-new', 2, details: fresh),
          ],
        ),
      );

      expect(result.bookmarks.single.slug, 'solo-leveling-new');
      expect(result.bookmarks.single.updatedDate, at(9));
    });
  });

  test('sync merge prefers the migrated copy on equal dates', () {
    final merged = SyncSnapshot.merge(
      SyncSnapshot(bookmarks: [bookmark('solo', 5)]),
      SyncSnapshot(bookmarks: [bookmark('solo', 5, details: fresh)]),
      keepDeletionsSince: keepSince,
    );

    expect(merged.bookmarks.single.comicDetails, fresh);
  });

  test('MigrateLocalLibrary writes only when something changed', () async {
    final repo = MockSyncRepository();
    final lookup = MockLookup();
    final clock = FixedClock(now);
    registerFallbackValue(const SyncSnapshot());
    when(() => repo.writeLocal(any())).thenAnswer((_) async => right(unit));
    final legacy = SyncSnapshot(bookmarks: [bookmark('solo', 5)]);
    when(() => repo.readLocal()).thenAnswer((_) async => right(legacy));
    when(() => lookup.find('solo', any()))
        .thenAnswer((_) async => right((slug: 'solo', details: fresh)));
    final useCase = MigrateLocalLibrary(
      repo,
      MigrateSnapshot(lookup, clock),
      clock,
    );

    expect(await useCase(const NoParams()), right(true));
    final written =
        verify(() => repo.writeLocal(captureAny())).captured.single
            as SyncSnapshot;
    expect(written.bookmarks.single.comicDetails, fresh);

    when(() => repo.readLocal()).thenAnswer((_) async => right(written));
    expect(await useCase(const NoParams()), right(false));
    verifyNever(() => repo.writeLocal(any()));
  });

  group('SeriesLookupRepositoryImpl', () {
    late MockApiClient client;
    late SeriesLookupRepositoryImpl repo;

    setUp(() {
      client = MockApiClient();
      repo = SeriesLookupRepositoryImpl(
        SeriesRemoteDataSourceImpl(client),
        FakeNetworkInfo(),
      );
      when(() => client.get('/series/solo-leveling/chapters'))
          .thenAnswer((_) async => {'data': chapterList});
    });

    test('keeps the slug when the series still exists', () async {
      when(() => client.get('/series/solo-leveling'))
          .thenAnswer((_) async => {'data': seriesDetail});

      final match = (await repo.find(
        'solo-leveling',
        sampleComicDetails,
      )).getOrElse((f) => throw f)!;

      expect(match.slug, 'solo-leveling');
      expect(match.details.source, ComicSource.current);
      verifyNever(() => client.get('/series', query: any(named: 'query')));
    });

    test('finds a renamed series by title', () async {
      when(() => client.get('/series/old-solo'))
          .thenThrow(const ServerException('Not found', statusCode: 404));
      when(() => client.get('/series', query: any(named: 'query'))).thenAnswer(
        (_) async => listResponse([
          {...seriesListItem, 'title': 'Solo Leveling: Ragnarok', 'slug': 'x'},
          {...seriesListItem, 'title': 'Solo  Leveling!'},
        ]),
      );
      when(() => client.get('/series/solo-leveling'))
          .thenAnswer((_) async => {'data': seriesDetail});

      final match = (await repo.find(
        'old-solo',
        sampleComicDetails,
      )).getOrElse((f) => throw f)!;

      expect(match.slug, 'solo-leveling');
      expect(match.details.chapters.first.slug, 'solo-leveling/2');
    });

    test('null when no title matches', () async {
      when(() => client.get('/series/old-solo'))
          .thenThrow(const ServerException('Not found', statusCode: 404));
      when(() => client.get('/series', query: any(named: 'query')))
          .thenAnswer((_) async => listResponse([]));

      expect(await repo.find('old-solo', sampleComicDetails), right(null));
    });

    test('other errors are failures, to retry later', () async {
      when(
        () => client.get('/series/solo-leveling'),
      ).thenThrow(const ServerException('Too many requests', statusCode: 429));

      expect(
        (await repo.find('solo-leveling', sampleComicDetails)).isLeft(),
        isTrue,
      );
    });
  });

  test('stored details keep source, and old data reads as null', () {
    final json = ComicDetailsModel.fromEntity(fresh).toJson();
    expect(json['source'], ComicSource.current);
    expect(ComicDetailsModel.fromJson(json).toEntity(), fresh);

    final old = ComicDetailsModel.fromEntity(sampleComicDetails).toJson();
    expect(old.containsKey('source'), isFalse);
    expect(ComicDetailsModel.fromJson(old).toEntity().source, isNull);
  });
}
