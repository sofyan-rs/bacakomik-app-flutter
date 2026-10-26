import 'package:bacakomik_app/core/data/datasources/series_remote_data_source.dart';
import 'package:bacakomik_app/core/domain/entities/comic.dart';
import 'package:bacakomik_app/core/error/exceptions.dart';
import 'package:bacakomik_app/core/error/failures.dart';
import 'package:bacakomik_app/core/presentation/bloc/comic_list_state.dart';
import 'package:bacakomik_app/core/source/extension_manager.dart';
import 'package:bacakomik_app/core/source/extension_meta.dart';
import 'package:bacakomik_app/features/explore/data/repositories/explore_repository_impl.dart';
import 'package:bacakomik_app/features/explore/domain/entities/explore_filter.dart';
import 'package:bacakomik_app/features/explore/domain/usecases/explore_comics.dart';
import 'package:bacakomik_app/features/explore/presentation/bloc/explore_bloc.dart';
import 'package:bacakomik_app/features/explore/presentation/bloc/filter_cubit.dart';
import 'package:bacakomik_app/features/latest/data/repositories/latest_repository_impl.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../fixtures/api_fixtures.dart';
import '../helpers/fake_source.dart';
import '../helpers/mocks.dart';

class MockExploreComics extends Mock implements ExploreComics {}

void main() {
  late FakeSourceBackend backend;
  late FakeSourceRegistry sources;
  late SeriesRemoteDataSource remote;
  late FakeNetworkInfo network;

  setUp(() {
    backend = FakeSourceBackend(
      responses: {'browse': browseResponse([seriesListItem], hasNext: true)},
      sourceFeatures: const SourceFeatures(
        latest: {
          'sort': ['latest'],
        },
      ),
    );
    sources = FakeSourceRegistry({
      'bacakomik': backend,
      'voratoon': backend,
    }, activeSource: 'bacakomik');
    remote = SeriesRemoteDataSourceImpl(sources);
    network = FakeNetworkInfo();
  });

  Map<Object?, Object?> browseRequest() =>
      backend.argsOf('browse').single! as Map;

  group('SeriesRemoteDataSourceImpl.getSeriesList', () {
    test('sends paging, search and filters to browse', () async {
      await remote.getSeriesList(
        'bacakomik',
        page: 2,
        limit: 5,
        query: 'solo',
        filters: {
          'genre': ['action'],
        },
      );

      expect(browseRequest(), {
        'page': 2,
        'limit': 5,
        'query': 'solo',
        'filters': {
          'genre': ['action'],
        },
      });
    });

    test('defaults to 30 items without search or filters', () async {
      await remote.getSeriesList('bacakomik');

      expect(browseRequest(), {
        'page': 1,
        'limit': 30,
        'query': null,
        'filters': <String, List<String>>{},
      });
    });

    test('rewrites slugs to keys of the source', () async {
      final bare = await remote.getSeriesList('bacakomik');
      final prefixed = await remote.getSeriesList('voratoon');

      expect(bare.single.slug, 'solo-leveling');
      expect(prefixed.single.slug, 'voratoon:solo-leveling');
    });

    test('rejects a result without items', () async {
      backend.responses['browse'] = {'hasNext': false};

      await expectLater(
        remote.getSeriesList('bacakomik'),
        throwsA(isA<ServerException>()),
      );
    });
  });

  group('LatestRepositoryImpl', () {
    test('requests the latest filters of the active source by page', () async {
      final result = await LatestRepositoryImpl(
        remote,
        network,
        sources,
      ).getLatest(3);

      final comic = result.getOrElse((f) => throw f).single;
      expect(comic.completed, isTrue);
      expect(comic.slug, 'solo-leveling');
      expect(browseRequest()['filters'], {
        'sort': ['latest'],
      });
      expect(browseRequest()['page'], 3);
    });

    test('no active source gives ServerFailure', () async {
      sources.activeSource = null;

      final result = await LatestRepositoryImpl(
        remote,
        network,
        sources,
      ).getLatest(1);

      expect(result.getLeft().toNullable()?.message, noSourceMessage);
      expect(backend.calls, isEmpty);
    });
  });

  group('ExploreRepositoryImpl', () {
    test('passes the filter values to the filter source', () async {
      final result = await ExploreRepositoryImpl(remote, network).explore(
        const ExploreFilter(
          source: 'voratoon',
          values: {
            'genre': ['action'],
            'status': ['completed'],
          },
        ),
        1,
      );

      expect(
        result.getOrElse((f) => throw f).single.slug,
        'voratoon:solo-leveling',
      );
      expect(sources.requested, ['voratoon']);
      expect(browseRequest()['filters'], {
        'genre': ['action'],
        'status': ['completed'],
      });
      expect(browseRequest()['query'], isNull);
    });

    test('sends the trimmed search together with the filters', () async {
      final result = await ExploreRepositoryImpl(remote, network).explore(
        const ExploreFilter(
          source: 'bacakomik',
          query: ' solo ',
          values: {
            'format': ['manhwa'],
          },
        ),
        2,
      );

      expect(result.getOrElse((f) => throw f).single.title, 'Solo Leveling');
      expect(browseRequest()['query'], 'solo');
      expect(browseRequest()['filters'], {
        'format': ['manhwa'],
      });
      expect(browseRequest()['page'], 2);
    });

    test('blank search is no search', () async {
      await ExploreRepositoryImpl(remote, network).explore(
        const ExploreFilter(source: 'bacakomik', query: '   '),
        1,
      );

      expect(browseRequest()['query'], isNull);
    });

    test('offline gives NetworkFailure', () async {
      network.connected = false;

      final result = await ExploreRepositoryImpl(
        remote,
        network,
      ).explore(const ExploreFilter(source: 'bacakomik'), 1);

      expect(result, left(const NetworkFailure()));
      expect(backend.calls, isEmpty);
    });
  });

  group('FilterCubit', () {
    blocTest<FilterCubit, ExploreFilter>(
      'setSource resets filters and search',
      build: FilterCubit.new,
      seed: () => const ExploreFilter(
        source: 'bacakomik',
        values: {
          'genre': ['1'],
        },
        query: 'solo',
      ),
      act: (cubit) => cubit.setSource('voratoon'),
      expect: () => [const ExploreFilter(source: 'voratoon')],
    );

    blocTest<FilterCubit, ExploreFilter>(
      'setSource to the same source keeps the filter',
      build: FilterCubit.new,
      seed: () => const ExploreFilter(source: 'bacakomik', query: 'solo'),
      act: (cubit) => cubit.setSource('bacakomik'),
      expect: () => <ExploreFilter>[],
    );

    blocTest<FilterCubit, ExploreFilter>(
      'setValue sets one group and keeps the rest',
      build: FilterCubit.new,
      seed: () => const ExploreFilter(
        source: 'bacakomik',
        values: {
          'status': ['ongoing'],
        },
        query: 'solo',
      ),
      act: (cubit) => cubit.setValue('genre', ['1', '2']),
      expect: () => [
        const ExploreFilter(
          source: 'bacakomik',
          values: {
            'status': ['ongoing'],
            'genre': ['1', '2'],
          },
          query: 'solo',
        ),
      ],
    );

    blocTest<FilterCubit, ExploreFilter>(
      'setValues replaces every value and keeps the search',
      build: FilterCubit.new,
      seed: () => const ExploreFilter(
        source: 'bacakomik',
        values: {
          'status': ['ongoing'],
        },
        query: 'solo',
      ),
      act: (cubit) => cubit.setValues({
        'sort': ['az'],
      }),
      expect: () => [
        const ExploreFilter(
          source: 'bacakomik',
          values: {
            'sort': ['az'],
          },
          query: 'solo',
        ),
      ],
    );

    blocTest<FilterCubit, ExploreFilter>(
      'showGenre clears everything but the genre',
      build: FilterCubit.new,
      seed: () => const ExploreFilter(
        source: 'bacakomik',
        values: {
          'status': ['ongoing'],
        },
        query: 'solo',
      ),
      act: (cubit) => cubit.showGenre('voratoon', 'genre', '7'),
      expect: () => [
        const ExploreFilter(
          source: 'voratoon',
          values: {
            FilterGroup.genreKey: ['7'],
          },
        ),
      ],
    );

    blocTest<FilterCubit, ExploreFilter>(
      'setQuery keeps the filters',
      build: FilterCubit.new,
      seed: () => const ExploreFilter(
        source: 'bacakomik',
        values: {
          'genre': ['1'],
        },
      ),
      act: (cubit) => cubit.setQuery('solo'),
      expect: () => [
        const ExploreFilter(
          source: 'bacakomik',
          values: {
            'genre': ['1'],
          },
          query: 'solo',
        ),
      ],
    );
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
      'next page skips comics already listed',
      setUp: () {
        when(() => explore((filter: filter, page: 1)))
            .thenAnswer((_) async => right([a]));
        when(() => explore((filter: filter, page: 2)))
            .thenAnswer((_) async => right([a, b]));
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
      'next page while another loads is ignored',
      setUp: () {
        when(() => explore((filter: filter, page: 1)))
            .thenAnswer((_) async => right([a]));
        when(() => explore((filter: filter, page: 2))).thenAnswer((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 20));
          return right([b]);
        });
      },
      build: () => ExploreBloc(explore),
      wait: const Duration(milliseconds: 50),
      act: (bloc) async {
        bloc.add(const ExploreRequested(filter: filter));
        await Future<void>.delayed(Duration.zero);
        bloc
          ..add(const ExploreNextPageRequested(filter: filter, page: 2))
          ..add(const ExploreNextPageRequested(filter: filter, page: 2));
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
