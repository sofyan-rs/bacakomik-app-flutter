import 'package:bacakomik_app/core/data/datasources/series_remote_data_source.dart';
import 'package:bacakomik_app/core/error/failures.dart';
import 'package:bacakomik_app/core/network/network_info.dart';
import 'package:bacakomik_app/core/network/remote_call.dart';
import 'package:bacakomik_app/features/home/domain/entities/home.dart';
import 'package:bacakomik_app/features/home/domain/repositories/home_repository.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: HomeRepository)
class HomeRepositoryImpl implements HomeRepository {
  const HomeRepositoryImpl(this._remote, this._networkInfo);

  final SeriesRemoteDataSource _remote;
  final NetworkInfo _networkInfo;

  @override
  Future<Either<Failure, Home>> getHome() => runRemote(_networkInfo, () async {
        final [newSeries, latest] = await Future.wait([
          _remote.getSeriesList(sort: 'newseries', limit: 10),
          _remote.getSeriesList(sort: 'latest', limit: 20),
        ]);
        return Home(
          newSeries: newSeries.map((e) => e.toEntity()).toList(),
          latest: latest.map((e) => e.toEntity()).toList(),
        );
      });
}
