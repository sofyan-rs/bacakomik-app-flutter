// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'package:bacakomik_app/core/data/datasources/series_remote_data_source.dart'
    as _i535;
import 'package:bacakomik_app/core/di/register_module.dart' as _i600;
import 'package:bacakomik_app/core/network/api_client.dart' as _i430;
import 'package:bacakomik_app/core/network/network_info.dart' as _i764;
import 'package:bacakomik_app/features/explore/data/repositories/explore_repository_impl.dart'
    as _i912;
import 'package:bacakomik_app/features/explore/domain/repositories/explore_repository.dart'
    as _i215;
import 'package:bacakomik_app/features/explore/domain/usecases/explore_comics.dart'
    as _i520;
import 'package:bacakomik_app/features/explore/presentation/bloc/explore_bloc.dart'
    as _i793;
import 'package:bacakomik_app/features/explore/presentation/bloc/filter_cubit.dart'
    as _i750;
import 'package:bacakomik_app/features/home/data/repositories/home_repository_impl.dart'
    as _i899;
import 'package:bacakomik_app/features/home/domain/repositories/home_repository.dart'
    as _i15;
import 'package:bacakomik_app/features/home/domain/usecases/get_home.dart'
    as _i611;
import 'package:bacakomik_app/features/home/presentation/bloc/home_bloc.dart'
    as _i568;
import 'package:bacakomik_app/features/latest/data/repositories/latest_repository_impl.dart'
    as _i968;
import 'package:bacakomik_app/features/latest/domain/repositories/latest_repository.dart'
    as _i655;
import 'package:bacakomik_app/features/latest/domain/usecases/get_latest_comics.dart'
    as _i328;
import 'package:bacakomik_app/features/latest/presentation/bloc/latest_bloc.dart'
    as _i768;
import 'package:bacakomik_app/features/search/data/repositories/search_repository_impl.dart'
    as _i758;
import 'package:bacakomik_app/features/search/domain/repositories/search_repository.dart'
    as _i1022;
import 'package:bacakomik_app/features/search/domain/usecases/search_comics.dart'
    as _i806;
import 'package:bacakomik_app/features/search/presentation/bloc/search_bloc.dart'
    as _i452;
import 'package:connectivity_plus/connectivity_plus.dart' as _i895;
import 'package:dio/dio.dart' as _i361;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final registerModule = _$RegisterModule();
    gh.factory<_i750.FilterCubit>(() => _i750.FilterCubit());
    gh.lazySingleton<_i361.Dio>(() => registerModule.dio);
    gh.lazySingleton<_i895.Connectivity>(() => registerModule.connectivity);
    gh.lazySingleton<_i430.ApiClient>(() => _i430.ApiClient(gh<_i361.Dio>()));
    gh.lazySingleton<_i764.NetworkInfo>(
      () => _i764.NetworkInfoImpl(gh<_i895.Connectivity>()),
    );
    gh.lazySingleton<_i535.SeriesRemoteDataSource>(
      () => _i535.SeriesRemoteDataSourceImpl(gh<_i430.ApiClient>()),
    );
    gh.lazySingleton<_i215.ExploreRepository>(
      () => _i912.ExploreRepositoryImpl(
        gh<_i535.SeriesRemoteDataSource>(),
        gh<_i764.NetworkInfo>(),
      ),
    );
    gh.lazySingleton<_i655.LatestRepository>(
      () => _i968.LatestRepositoryImpl(
        gh<_i535.SeriesRemoteDataSource>(),
        gh<_i764.NetworkInfo>(),
      ),
    );
    gh.factory<_i328.GetLatestComics>(
      () => _i328.GetLatestComics(gh<_i655.LatestRepository>()),
    );
    gh.lazySingleton<_i1022.SearchRepository>(
      () => _i758.SearchRepositoryImpl(
        gh<_i535.SeriesRemoteDataSource>(),
        gh<_i764.NetworkInfo>(),
      ),
    );
    gh.lazySingleton<_i15.HomeRepository>(
      () => _i899.HomeRepositoryImpl(
        gh<_i535.SeriesRemoteDataSource>(),
        gh<_i764.NetworkInfo>(),
      ),
    );
    gh.factory<_i611.GetHome>(() => _i611.GetHome(gh<_i15.HomeRepository>()));
    gh.factory<_i806.SearchComics>(
      () => _i806.SearchComics(gh<_i1022.SearchRepository>()),
    );
    gh.factory<_i452.SearchBloc>(
      () => _i452.SearchBloc(gh<_i806.SearchComics>()),
    );
    gh.factory<_i520.ExploreComics>(
      () => _i520.ExploreComics(gh<_i215.ExploreRepository>()),
    );
    gh.factory<_i768.LatestBloc>(
      () => _i768.LatestBloc(gh<_i328.GetLatestComics>()),
    );
    gh.factory<_i568.HomeBloc>(() => _i568.HomeBloc(gh<_i611.GetHome>()));
    gh.factory<_i793.ExploreBloc>(
      () => _i793.ExploreBloc(gh<_i520.ExploreComics>()),
    );
    return this;
  }
}

class _$RegisterModule extends _i600.RegisterModule {}
