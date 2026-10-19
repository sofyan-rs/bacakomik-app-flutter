import 'package:bacakomik_app/core/data/datasources/series_remote_data_source.dart';
import 'package:bacakomik_app/core/domain/entities/comic.dart';
import 'package:bacakomik_app/core/error/failures.dart';
import 'package:bacakomik_app/core/presentation/bloc/comic_list_state.dart';
import 'package:bacakomik_app/features/explore/data/repositories/explore_repository_impl.dart';
import 'package:bacakomik_app/features/explore/domain/entities/explore_filter.dart';
import 'package:bacakomik_app/features/latest/data/repositories/latest_repository_impl.dart';
import 'package:bacakomik_app/features/search/data/repositories/search_repository_impl.dart';
import 'package:bacakomik_app/features/search/domain/usecases/search_comics.dart';
import 'package:bacakomik_app/features/search/presentation/bloc/search_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../fixtures/api_fixtures.dart';
import '../helpers/mocks.dart';

class MockSearchComics extends Mock implements SearchComics {}

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
          .single as Map;

  test('LatestRepositoryImpl requests latest sort by page', () async {
    final result = await LatestRepositoryImpl(remote, network).getLatest(3);

    final comic = result.getOrElse((f) => throw f).single;
    expect(comic.completed, isTrue);
    expect(comic.slug, 'solo-leveling');
    final query = capturedQuery();
    expect(query['sort'], 'latest');
    expect(query['page'], 3);
  });

  test('SearchRepositoryImpl passes keyword and page', () async {
    final result =
        await SearchRepositoryImpl(remote, network).search('solo', 2);

    expect(result.getOrElse((f) => throw f).single.title, 'Solo Leveling');
    final query = capturedQuery();
    expect(query['q'], 'solo');
    expect(query['page'], 2);
  });

  group('ExploreRepositoryImpl', () {
    test('drops default/all filters', () async {
      await ExploreRepositoryImpl(remote, network).explore(
        const ExploreFilter(sortBy: 'default', genres: ['action']),
        1,
      );

      final query = capturedQuery();
      expect(query['sort'], isNull);
      expect(query['status'], isNull);
      expect(query['format'], isNull);
      expect(query['genre'], 'action');
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

  group('SearchBloc paging', () {
    late MockSearchComics search;
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

    setUp(() => search = MockSearchComics());

    blocTest<SearchBloc, ComicListState>(
      'first page then next page appends',
      setUp: () {
        when(() => search((keyword: 'x', page: 1)))
            .thenAnswer((_) async => right([a]));
        when(() => search((keyword: 'x', page: 2)))
            .thenAnswer((_) async => right([b]));
      },
      build: () => SearchBloc(search),
      act: (bloc) async {
        bloc.add(const SearchRequested(keyword: 'x'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const SearchNextPageRequested(keyword: 'x', page: 2));
      },
      expect: () => [
        const ComicListState.loading(),
        const ComicListState.loaded(comics: [a]),
        const ComicListState.loaded(comics: [a], isLoadMore: true),
        ComicListState.loaded(comics: [a, b]),
      ],
    );

    blocTest<SearchBloc, ComicListState>(
      'next page before first load is ignored',
      build: () => SearchBloc(search),
      act: (bloc) =>
          bloc.add(const SearchNextPageRequested(keyword: 'x', page: 2)),
      expect: () => <ComicListState>[],
    );

    blocTest<SearchBloc, ComicListState>(
      'offline maps to noInternet',
      setUp: () => when(() => search((keyword: 'x', page: 1)))
          .thenAnswer((_) async => left(const NetworkFailure())),
      build: () => SearchBloc(search),
      act: (bloc) => bloc.add(const SearchRequested(keyword: 'x')),
      expect: () => [
        const ComicListState.loading(),
        const ComicListState.noInternet(),
      ],
    );
  });
}
