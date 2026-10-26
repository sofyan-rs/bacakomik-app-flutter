import 'package:bacakomik_app/core/data/datasources/series_remote_data_source.dart';
import 'package:bacakomik_app/core/data/models/series_response.dart';
import 'package:bacakomik_app/core/error/exceptions.dart';
import 'package:bacakomik_app/core/error/failures.dart';
import 'package:bacakomik_app/core/network/network_info.dart';
import 'package:bacakomik_app/core/network/remote_call.dart';
import 'package:bacakomik_app/core/source/extension_manager.dart';
import 'package:bacakomik_app/features/home/domain/entities/home.dart';
import 'package:bacakomik_app/features/home/domain/repositories/home_repository.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: HomeRepository)
class HomeRepositoryImpl implements HomeRepository {
  const HomeRepositoryImpl(this._remote, this._networkInfo, this._sources);

  final SeriesRemoteDataSource _remote;
  final NetworkInfo _networkInfo;
  final SourceRegistry _sources;

  @override
  Future<Either<Failure, Home>> getHome() => runRemote(_networkInfo, () async {
    final source = _sources.activeSource;
    if (source == null) throw const ServerException(noSourceMessage);
    final features = await (await _sources.backend(source)).features();
    final [newSeries, latest] = await Future.wait([
      if (features.showFeatured)
        _remote.getSeriesList(source, filters: features.featured, limit: 10)
      else
        Future.value(const <SeriesResponse>[]),
      _remote.getSeriesList(source, filters: features.latest, limit: 20),
    ]);
    return Home(
      newSeries: newSeries.map((e) => e.toEntity()).toList(),
      latest: latest.map((e) => e.toEntity()).toList(),
    );
  });
}
