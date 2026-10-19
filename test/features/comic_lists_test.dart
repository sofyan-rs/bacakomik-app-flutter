import 'package:bacakomik_app/core/data/datasources/series_remote_data_source.dart';
import 'package:bacakomik_app/core/domain/entities/comic.dart';
import 'package:bacakomik_app/core/error/failures.dart';
import 'package:bacakomik_app/core/presentation/bloc/comic_list_state.dart';
import 'package:bacakomik_app/features/explore/data/repositories/explore_repository_impl.dart';
import 'package:bacakomik_app/features/explore/domain/entities/explore_filter.dart';
import 'package:bacakomik_app/features/latest/data/repositories/latest_repository_impl.dart';
import 'package:bacakomik_app/features/explore/domain/usecases/explore_comics.dart';
import 'package:bacakomik_app/features/explore/presentation/bloc/explore_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../fixtures/api_fixtures.dart';
import '../helpers/mocks.dart';

class MockExploreComics extends Mock implements ExploreComics {}

void main() {
  late MockApiClient client;
  late SeriesRemoteDataSource remote;
  late FakeNetworkInfo network;

  setUp(() {
    client = MockApiClient();
    remote = SeriesRemoteDataSourceImpl(client);
    network = FakeNetworkInfo();
    when(() => client.get('/series', query: any(named: 'query')))
        .thenAnswer((_) async => listResponse([seriesListItem]));
  });

  Map capturedQuery() =>
      verify(() => client.get('/series', query: captureAny(named: 'query')))
              .captured
              .single
          as Map;

  test('LatestRepositoryImpl requests latest sort by page', () async {
    final result = await LatestRepositoryImpl(remote, network).getLatest(3);

    final comic = result.getOrElse((f) => throw f).single;
    expect(comic.completed, isTrue);
    expect(comic.slug, 'solo-leveling');
    final query = capturedQuery();
    expect(query['sort'], 'latest');
    expect(query['page'], 3);
  });

  group('ExploreRepositoryImpl', () {
    test('drops default/all filters', () async {
      await ExploreRepositoryImpl(
        remote,
        network,
      ).explore(const ExploreFilter(sortBy: 'default', genres: ['action']), 1);

      final query = capturedQuery();
      expect(query['sort'], isNull);
      expect(query['status'], isNull);
      expect(query['format'], isNull);
      expect(query['genre'], 'action');
      expect(query['q'], isNull);
    });

    test('sends the search together with the filters', () async {
      final result = await ExploreRepositoryImpl(remote, network).explore(
        const ExploreFilter(query: ' solo ', type: 'manhwa', sortBy: 'az'),
        2,
      );

      expect(result.getOrElse((f) => throw f).single.title, 'Solo Leveling');
      final query = capturedQuery();
      expect(query['q'], 'solo');
      expect(query['format'], 'manhwa');
      expect(query['sort'], 'az');
      expect(query['page'], 2);
    });

    test('passes concrete filters', () async {
      await ExploreRepositoryImpl(remote, network).explore(
        const ExploreFilter(
          sortBy: 'rating',
          status: 'completed',
          type: 'manga',
        ),
        2,
      );

      final query = capturedQuery();
      expect(query['sort'], 'rating');
      expect(query['status'], 'completed');
      expect(query['format'], 'manga');
      expect(query['page'], 2);
    });
  });

  group('ExploreBloc paging', () {
    late MockExploreComics explore;
    const filter = ExploreFilter(query: 'x');
    const a = Comic(
      title: 'A',
      coverImg: '',
      slug: 'a',
      type: '-',
      completed: false,
      rating: '-',
      latestChapter: '-',
    );
    final b = a.copyWith(slug: 'b');

    setUp(() => explore = MockExploreComics());

    blocTest<ExploreBloc, ComicListState>(
      'first page then next page appends',
      setUp: () {
        when(() => explore((filter: filter, page: 1)))
            .thenAnswer((_) async => right([a]));
        when(() => explore((filter: filter, page: 2)))
            .thenAnswer((_) async => right([b]));
      },
      build: () => ExploreBloc(explore),
      act: (bloc) async {
        bloc.add(const ExploreRequested(filter: filter));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const ExploreNextPageRequested(filter: filter, page: 2));
      },
      expect: () => [
        const ComicListState.loading(),
        const ComicListState.loaded(comics: [a]),
        const ComicListState.loaded(comics: [a], isLoadMore: true),
        ComicListState.loaded(comics: [a, b]),
      ],
    );

    blocTest<ExploreBloc, ComicListState>(
      'next page before first load is ignored',
      build: () => ExploreBloc(explore),
      act: (bloc) =>
          bloc.add(const ExploreNextPageRequested(filter: filter, page: 2)),
      expect: () => <ComicListState>[],
    );

    blocTest<ExploreBloc, ComicListState>(
      'offline maps to noInternet',
      setUp: () =>
          when(() => explore((filter: filter, page: 1)))
              .thenAnswer((_) async => left(const NetworkFailure())),
      build: () => ExploreBloc(explore),
      act: (bloc) => bloc.add(const ExploreRequested(filter: filter)),
      expect: () => [
        const ComicListState.loading(),
        const ComicListState.noInternet(),
      ],
    );

    blocTest<ExploreBloc, ComicListState>(
      'a slow earlier search cannot replace a newer one',
      setUp: () {
        when(() => explore((filter: const ExploreFilter(query: 'so'), page: 1)))
            .thenAnswer((_) async {
              await Future<void>.delayed(const Duration(milliseconds: 50));
              return right([a]);
            });
        when(() => explore((filter: filter, page: 1)))
            .thenAnswer((_) async => right([b]));
      },
      build: () => ExploreBloc(explore),
      act: (bloc) {
        bloc
          ..add(const ExploreRequested(filter: ExploreFilter(query: 'so')))
          ..add(const ExploreRequested(filter: filter));
      },
      wait: const Duration(milliseconds: 100),
      expect: () => [
        const ComicListState.loading(),
        const ComicListState.loaded(comics: [a]),
        const ComicListState.loading(),
        ComicListState.loaded(comics: [b]),
      ],
    );
  });
}
