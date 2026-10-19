import 'package:bacakomik_app/core/data/datasources/series_remote_data_source.dart';
import 'package:bacakomik_app/core/error/exceptions.dart';
import 'package:bacakomik_app/core/error/failures.dart';
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
import '../../helpers/mocks.dart';

class MockGetHome extends Mock implements GetHome {}

void main() {
  group('HomeRepositoryImpl', () {
    late MockApiClient client;
    late FakeNetworkInfo network;
    late HomeRepositoryImpl repository;

    setUp(() {
      client = MockApiClient();
      network = FakeNetworkInfo();
      repository =
          HomeRepositoryImpl(SeriesRemoteDataSourceImpl(client), network);
    });

    test('maps trending and latest lists', () async {
      when(() => client.get('/lists/trending',
              query: {'page': 1, 'limit': 10}))
          .thenAnswer((_) async => listResponse([seriesListItem]));
      when(() => client.get('/series', query: any(named: 'query')))
          .thenAnswer((_) async => listResponse([seriesListItemNulls]));

      final home = (await repository.getHome()).getOrElse((f) => throw f);

      final popular = home.popular.single;
      expect(popular.title, 'Solo Leveling');
      expect(popular.type, 'Manhwa');
      expect(popular.latestChapter, '200');
      expect(popular.rating, '9.3');

      final latest = home.latest.single;
      expect(latest.coverImg, '');
      expect(latest.type, '-');
      expect(latest.rating, '-');
      expect(latest.latestChapter, '-');
      expect(latest.completed, isFalse);

      final query = verify(() =>
              client.get('/series', query: captureAny(named: 'query')))
          .captured
          .single as Map;
      expect(query['sort'], 'latest');
      expect(query['limit'], 20);
    });

    test('returns NetworkFailure when offline', () async {
      network.connected = false;

      expect(await repository.getHome(), left(const NetworkFailure()));
      verifyZeroInteractions(client);
    });

    test('maps ServerException to ServerFailure', () async {
      when(() => client.get(any(), query: any(named: 'query')))
          .thenThrow(const ServerException('boom'));

      final failure = (await repository.getHome()).getLeft().toNullable();

      expect(failure, isA<ServerFailure>());
      expect(failure!.message, 'boom');
    });
  });

  group('HomeBloc', () {
    late MockGetHome getHome;
    const home = Home(popular: [], latest: []);

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
