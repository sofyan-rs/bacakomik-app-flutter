import 'package:bacakomik_app/core/data/datasources/series_remote_data_source.dart';
import 'package:bacakomik_app/core/error/exceptions.dart';
import 'package:bacakomik_app/core/error/failures.dart';
import 'package:bacakomik_app/core/source/extension_manager.dart';
import 'package:bacakomik_app/core/source/extension_meta.dart';
import 'package:bacakomik_app/core/usecase/usecase.dart';
import 'package:bacakomik_app/features/home/data/repositories/home_repository_impl.dart';
import 'package:bacakomik_app/features/home/domain/entities/home.dart';
import 'package:bacakomik_app/features/home/domain/usecases/get_home.dart';
import 'package:bacakomik_app/features/home/presentation/bloc/home_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../fixtures/api_fixtures.dart';
import '../../helpers/fake_source.dart';
import '../../helpers/mocks.dart';

class MockGetHome extends Mock implements GetHome {}

void main() {
  group('HomeRepositoryImpl', () {
    late FakeSourceBackend backend;
    late FakeSourceRegistry sources;
    late FakeNetworkInfo network;
    late HomeRepositoryImpl repository;

    setUp(() {
      backend = FakeSourceBackend(
        sourceFeatures: const SourceFeatures(
          featured: {
            'sort': ['newseries'],
          },
          latest: {
            'sort': ['latest'],
          },
        ),
      );
      sources = FakeSourceRegistry({
        'bacakomik': backend,
      }, activeSource: 'bacakomik');
      network = FakeNetworkInfo();
      repository = HomeRepositoryImpl(
        SeriesRemoteDataSourceImpl(sources),
        network,
        sources,
      );
    });

    test('maps featured and latest lists of the active source', () async {
      backend.responses['browse'] = (List<Object?> args) {
        final filters = (args.single! as Map)['filters'] as Map;
        return filters['sort'] == const ['newseries']
            ? browseResponse([seriesListItem])
            : browseResponse([seriesListItemNulls]);
      };

      final home = (await repository.getHome()).getOrElse((f) => throw f);

      final newSeries = home.newSeries.single;
      expect(newSeries.title, 'Solo Leveling');
      expect(newSeries.type, 'Manhwa');
      expect(newSeries.latestChapter, '200');
      expect(newSeries.rating, '9.3');

      final latest = home.latest.single;
      expect(latest.coverImg, '');
      expect(latest.type, '-');
      expect(latest.rating, '-');
      expect(latest.latestChapter, '-');
      expect(latest.completed, isFalse);

      final requests = backend.calls
          .where((c) => c.method == 'browse')
          .map((c) => c.args.single! as Map);
      expect(
        requests.map((r) => '${(r['filters'] as Map)['sort']} ${r['limit']}'),
        unorderedEquals(['[newseries] 10', '[latest] 20']),
      );
    });

    test('keys of another source are prefixed', () async {
      sources.backends['voratoon'] = backend;
      sources.activeSource = 'voratoon';
      backend.responses['browse'] = browseResponse([seriesListItem]);

      final home = (await repository.getHome()).getOrElse((f) => throw f);

      expect(home.newSeries.single.slug, 'voratoon:solo-leveling');
      expect(home.latest.single.slug, 'voratoon:solo-leveling');
    });

    test('no active source gives ServerFailure', () async {
      sources.activeSource = null;

      final failure = (await repository.getHome()).getLeft().toNullable();

      expect(failure, isA<ServerFailure>());
      expect(failure!.message, noSourceMessage);
      expect(backend.calls, isEmpty);
    });

    test('returns NetworkFailure when offline', () async {
      network.connected = false;

      expect(await repository.getHome(), left(const NetworkFailure()));
      expect(backend.calls, isEmpty);
    });

    test('maps ServerException to ServerFailure', () async {
      backend.responses['browse'] = const ServerException('boom');

      final failure = (await repository.getHome()).getLeft().toNullable();

      expect(failure, isA<ServerFailure>());
      expect(failure!.message, 'boom');
    });
  });

  group('HomeBloc', () {
    late MockGetHome getHome;
    const home = Home(newSeries: [], latest: []);

    setUp(() {
      getHome = MockGetHome();
      registerFallbackValue(const NoParams());
    });

    blocTest<HomeBloc, HomeState>(
      'started emits loading then loaded',
      setUp: () => when(() => getHome(any()))
          .thenAnswer((_) async => right(home)),
      build: () => HomeBloc(getHome),
      act: (bloc) => bloc.add(HomeStarted()),
      expect: () => [
        const HomeState.loading(),
        const HomeState.loaded(home: home),
      ],
    );

    blocTest<HomeBloc, HomeState>(
      'network failure emits noInternet',
      setUp: () => when(() => getHome(any()))
          .thenAnswer((_) async => left(const NetworkFailure())),
      build: () => HomeBloc(getHome),
      act: (bloc) => bloc.add(HomeStarted()),
      expect: () => [
        const HomeState.loading(),
        const HomeState.noInternet(),
      ],
    );

    blocTest<HomeBloc, HomeState>(
      'refresh keeps data visible while reloading',
      setUp: () => when(() => getHome(any()))
          .thenAnswer((_) async => right(home)),
      build: () => HomeBloc(getHome),
      seed: () => const HomeState.loaded(home: home),
      act: (bloc) => bloc.add(HomeRefreshed()),
      expect: () => [
        const HomeState.loaded(home: home, isRefetch: true),
        const HomeState.loaded(home: home),
      ],
    );

    blocTest<HomeBloc, HomeState>(
      'refresh before first load behaves like start',
      setUp: () => when(() => getHome(any()))
          .thenAnswer((_) async => left(const ServerFailure('x'))),
      build: () => HomeBloc(getHome),
      act: (bloc) => bloc.add(HomeRefreshed()),
      expect: () => [
        const HomeState.loading(),
        const HomeState.error(message: 'x'),
      ],
    );
  });
}
