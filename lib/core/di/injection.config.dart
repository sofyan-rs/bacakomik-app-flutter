// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'package:bacakomik_app/app/legacy_storage_migrator.dart' as _i458;
import 'package:bacakomik_app/core/data/datasources/series_remote_data_source.dart'
    as _i535;
import 'package:bacakomik_app/core/di/register_module.dart' as _i600;
import 'package:bacakomik_app/core/network/api_client.dart' as _i430;
import 'package:bacakomik_app/core/network/network_info.dart' as _i764;
import 'package:bacakomik_app/core/storage/hive_boxes.dart' as _i446;
import 'package:bacakomik_app/core/utils/clock.dart' as _i1011;
import 'package:bacakomik_app/features/backup/data/datasources/backup_file_data_source.dart'
    as _i713;
import 'package:bacakomik_app/features/backup/data/repositories/backup_repository_impl.dart'
    as _i878;
import 'package:bacakomik_app/features/backup/domain/repositories/backup_repository.dart'
    as _i152;
import 'package:bacakomik_app/features/backup/domain/usecases/backup_library.dart'
    as _i81;
import 'package:bacakomik_app/features/backup/presentation/bloc/backup_cubit.dart'
    as _i687;
import 'package:bacakomik_app/features/bookmark/data/datasources/bookmark_local_data_source.dart'
    as _i676;
import 'package:bacakomik_app/features/bookmark/data/repositories/bookmark_repository_impl.dart'
    as _i684;
import 'package:bacakomik_app/features/bookmark/domain/repositories/bookmark_repository.dart'
    as _i851;
import 'package:bacakomik_app/features/bookmark/domain/usecases/bookmark_usecases.dart'
    as _i501;
import 'package:bacakomik_app/features/bookmark/domain/usecases/refresh_bookmarks.dart'
    as _i527;
import 'package:bacakomik_app/features/bookmark/presentation/bloc/bookmark_cubit.dart'
    as _i518;
import 'package:bacakomik_app/features/comic_detail/data/repositories/comic_detail_repository_impl.dart'
    as _i363;
import 'package:bacakomik_app/features/comic_detail/domain/repositories/comic_detail_repository.dart'
    as _i282;
import 'package:bacakomik_app/features/comic_detail/domain/usecases/get_comic_details.dart'
    as _i380;
import 'package:bacakomik_app/features/comic_detail/presentation/bloc/comic_details_bloc.dart'
    as _i1013;
import 'package:bacakomik_app/features/explore/data/repositories/explore_repository_impl.dart'
    as _i912;
import 'package:bacakomik_app/features/explore/domain/repositories/explore_repository.dart'
    as _i215;
import 'package:bacakomik_app/features/explore/domain/usecases/explore_comics.dart'
    as _i520;
import 'package:bacakomik_app/features/explore/presentation/bloc/explore_bloc.dart'
    as _i794;
import 'package:bacakomik_app/features/explore/presentation/bloc/filter_cubit.dart'
    as _i750;
import 'package:bacakomik_app/features/history/data/datasources/history_local_data_source.dart'
    as _i793;
import 'package:bacakomik_app/features/history/data/repositories/history_repository_impl.dart'
    as _i262;
import 'package:bacakomik_app/features/history/domain/repositories/history_repository.dart'
    as _i55;
import 'package:bacakomik_app/features/history/domain/usecases/history_usecases.dart'
    as _i729;
import 'package:bacakomik_app/features/history/presentation/bloc/history_cubit.dart'
    as _i928;
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
import 'package:bacakomik_app/features/reader/data/repositories/reader_repository_impl.dart'
    as _i291;
import 'package:bacakomik_app/features/reader/domain/repositories/reader_repository.dart'
    as _i578;
import 'package:bacakomik_app/features/reader/domain/usecases/get_chapter_content.dart'
    as _i681;
import 'package:bacakomik_app/features/reader/presentation/bloc/reader_bloc.dart'
    as _i471;
import 'package:bacakomik_app/features/search/data/repositories/search_repository_impl.dart'
    as _i758;
import 'package:bacakomik_app/features/search/domain/repositories/search_repository.dart'
    as _i1022;
import 'package:bacakomik_app/features/search/domain/usecases/search_comics.dart'
    as _i806;
import 'package:bacakomik_app/features/search/presentation/bloc/search_bloc.dart'
    as _i452;
import 'package:bacakomik_app/features/settings/data/datasources/settings_local_data_source.dart'
    as _i394;
import 'package:bacakomik_app/features/settings/data/repositories/settings_repository_impl.dart'
    as _i314;
import 'package:bacakomik_app/features/settings/domain/repositories/settings_repository.dart'
    as _i551;
import 'package:bacakomik_app/features/settings/domain/usecases/settings_usecases.dart'
    as _i1063;
import 'package:bacakomik_app/features/settings/presentation/bloc/settings_cubit.dart'
    as _i625;
import 'package:connectivity_plus/connectivity_plus.dart' as _i895;
import 'package:dio/dio.dart' as _i361;
import 'package:get_it/get_it.dart' as _i174;
import 'package:hive_ce/hive.dart' as _i738;
import 'package:injectable/injectable.dart' as _i526;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  Future<_i174.GetIt> init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) async {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final registerModule = _$RegisterModule();
    final storageModule = _$StorageModule();
    gh.factory<_i750.FilterCubit>(() => _i750.FilterCubit());
    gh.lazySingleton<_i361.Dio>(() => registerModule.dio);
    gh.lazySingleton<_i895.Connectivity>(() => registerModule.connectivity);
    gh.lazySingleton<_i738.HiveInterface>(() => registerModule.hive);
    gh.lazySingleton<_i1011.Clock>(() => _i1011.Clock());
    gh.lazySingleton<_i713.BackupFileDataSource>(
      () => _i713.BackupFileDataSourceImpl(),
    );
    await gh.factoryAsync<_i738.Box<String>>(
      () => storageModule.bookmarksBox,
      instanceName: 'bookmarks',
      preResolve: true,
    );
    await gh.factoryAsync<_i738.Box<String>>(
      () => storageModule.settingsBox,
      instanceName: 'settings',
      preResolve: true,
    );
    gh.lazySingleton<_i676.BookmarkLocalDataSource>(
      () => _i676.BookmarkLocalDataSourceImpl(
        gh<_i738.Box<String>>(instanceName: 'bookmarks'),
      ),
    );
    gh.lazySingleton<_i394.SettingsLocalDataSource>(
      () => _i394.SettingsLocalDataSourceImpl(
        gh<_i738.Box<String>>(instanceName: 'settings'),
      ),
    );
    await gh.factoryAsync<_i738.Box<String>>(
      () => storageModule.historyBox,
      instanceName: 'history',
      preResolve: true,
    );
    gh.lazySingleton<_i430.ApiClient>(() => _i430.ApiClient(gh<_i361.Dio>()));
    await gh.factoryAsync<_i738.Box<String>>(
      () => storageModule.metaBox,
      instanceName: 'app_meta',
      preResolve: true,
    );
    gh.lazySingleton<_i551.SettingsRepository>(
      () => _i314.SettingsRepositoryImpl(gh<_i394.SettingsLocalDataSource>()),
    );
    gh.lazySingleton<_i851.BookmarkRepository>(
      () => _i684.BookmarkRepositoryImpl(gh<_i676.BookmarkLocalDataSource>()),
    );
    gh.lazySingleton<_i764.NetworkInfo>(
      () => _i764.NetworkInfoImpl(gh<_i895.Connectivity>()),
    );
    gh.factory<_i1063.GetSettings>(
      () => _i1063.GetSettings(gh<_i551.SettingsRepository>()),
    );
    gh.factory<_i1063.SaveSettings>(
      () => _i1063.SaveSettings(gh<_i551.SettingsRepository>()),
    );
    gh.lazySingleton<_i793.HistoryLocalDataSource>(
      () => _i793.HistoryLocalDataSourceImpl(
        gh<_i738.Box<String>>(instanceName: 'history'),
      ),
    );
    gh.factory<_i501.GetBookmarks>(
      () => _i501.GetBookmarks(gh<_i851.BookmarkRepository>()),
    );
    gh.factory<_i501.SaveBookmarks>(
      () => _i501.SaveBookmarks(gh<_i851.BookmarkRepository>()),
    );
    gh.factory<_i501.RemoveBookmarks>(
      () => _i501.RemoveBookmarks(gh<_i851.BookmarkRepository>()),
    );
    gh.lazySingleton<_i152.BackupRepository>(
      () => _i878.BackupRepositoryImpl(
        gh<_i713.BackupFileDataSource>(),
        gh<_i1011.Clock>(),
      ),
    );
    gh.lazySingleton<_i55.HistoryRepository>(
      () => _i262.HistoryRepositoryImpl(gh<_i793.HistoryLocalDataSource>()),
    );
    gh.lazySingleton<_i535.SeriesRemoteDataSource>(
      () => _i535.SeriesRemoteDataSourceImpl(gh<_i430.ApiClient>()),
    );
    gh.lazySingleton<_i458.LegacyStorageMigrator>(
      () => _i458.LegacyStorageMigrator(
        gh<_i738.HiveInterface>(),
        gh<_i738.Box<String>>(instanceName: 'app_meta'),
        gh<_i676.BookmarkLocalDataSource>(),
        gh<_i793.HistoryLocalDataSource>(),
        gh<_i394.SettingsLocalDataSource>(),
      ),
    );
    gh.factory<_i625.SettingsCubit>(
      () => _i625.SettingsCubit(
        gh<_i1063.GetSettings>(),
        gh<_i1063.SaveSettings>(),
      ),
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
    gh.lazySingleton<_i578.ReaderRepository>(
      () => _i291.ReaderRepositoryImpl(
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
    gh.lazySingleton<_i282.ComicDetailRepository>(
      () => _i363.ComicDetailRepositoryImpl(
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
    gh.factory<_i729.GetHistory>(
      () => _i729.GetHistory(gh<_i55.HistoryRepository>()),
    );
    gh.factory<_i729.SaveHistory>(
      () => _i729.SaveHistory(gh<_i55.HistoryRepository>()),
    );
    gh.factory<_i729.RemoveHistory>(
      () => _i729.RemoveHistory(gh<_i55.HistoryRepository>()),
    );
    gh.factory<_i729.RemoveComicHistory>(
      () => _i729.RemoveComicHistory(gh<_i55.HistoryRepository>()),
    );
    gh.factory<_i729.ClearHistory>(
      () => _i729.ClearHistory(gh<_i55.HistoryRepository>()),
    );
    gh.factory<_i81.BackupLibrary>(
      () => _i81.BackupLibrary(
        gh<_i152.BackupRepository>(),
        gh<_i851.BookmarkRepository>(),
        gh<_i55.HistoryRepository>(),
      ),
    );
    gh.factory<_i81.RestoreLibrary>(
      () => _i81.RestoreLibrary(
        gh<_i152.BackupRepository>(),
        gh<_i851.BookmarkRepository>(),
        gh<_i55.HistoryRepository>(),
      ),
    );
    gh.factory<_i687.BackupCubit>(
      () => _i687.BackupCubit(
        gh<_i81.BackupLibrary>(),
        gh<_i81.RestoreLibrary>(),
      ),
    );
    gh.factory<_i380.GetComicDetails>(
      () => _i380.GetComicDetails(gh<_i282.ComicDetailRepository>()),
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
    gh.factory<_i681.GetChapterContent>(
      () => _i681.GetChapterContent(gh<_i578.ReaderRepository>()),
    );
    gh.factory<_i768.LatestBloc>(
      () => _i768.LatestBloc(gh<_i328.GetLatestComics>()),
    );
    gh.factory<_i527.RefreshBookmarks>(
      () => _i527.RefreshBookmarks(
        gh<_i851.BookmarkRepository>(),
        gh<_i282.ComicDetailRepository>(),
        gh<_i1011.Clock>(),
      ),
    );
    gh.factory<_i928.HistoryCubit>(
      () => _i928.HistoryCubit(
        gh<_i729.GetHistory>(),
        gh<_i729.SaveHistory>(),
        gh<_i729.RemoveHistory>(),
        gh<_i729.RemoveComicHistory>(),
        gh<_i729.ClearHistory>(),
        gh<_i1011.Clock>(),
      ),
    );
    gh.factory<_i471.ReaderBloc>(
      () => _i471.ReaderBloc(gh<_i681.GetChapterContent>()),
    );
    gh.factory<_i518.BookmarkCubit>(
      () => _i518.BookmarkCubit(
        gh<_i501.GetBookmarks>(),
        gh<_i501.SaveBookmarks>(),
        gh<_i501.RemoveBookmarks>(),
        gh<_i527.RefreshBookmarks>(),
        gh<_i1011.Clock>(),
      ),
    );
    gh.factory<_i568.HomeBloc>(() => _i568.HomeBloc(gh<_i611.GetHome>()));
    gh.factory<_i794.ExploreBloc>(
      () => _i794.ExploreBloc(gh<_i520.ExploreComics>()),
    );
    gh.factory<_i1013.ComicDetailsBloc>(
      () => _i1013.ComicDetailsBloc(gh<_i380.GetComicDetails>()),
    );
    return this;
  }
}

class _$RegisterModule extends _i600.RegisterModule {}

class _$StorageModule extends _i446.StorageModule {}
