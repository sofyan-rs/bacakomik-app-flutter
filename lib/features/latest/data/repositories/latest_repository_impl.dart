import 'package:bacakomik_app/core/data/datasources/series_remote_data_source.dart';
import 'package:bacakomik_app/core/domain/entities/comic.dart';
import 'package:bacakomik_app/core/error/failures.dart';
import 'package:bacakomik_app/core/network/network_info.dart';
import 'package:bacakomik_app/core/network/remote_call.dart';
import 'package:bacakomik_app/features/latest/domain/repositories/latest_repository.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: LatestRepository)
class LatestRepositoryImpl implements LatestRepository {
  const LatestRepositoryImpl(this._remote, this._networkInfo);

  final SeriesRemoteDataSource _remote;
  final NetworkInfo _networkInfo;

  @override
  Future<Either<Failure, List<Comic>>> getLatest(int page) =>
      runRemote(_networkInfo, () async {
        final res = await _remote.getSeriesList(sort: 'latest', page: page);
        return res.map((e) => e.toEntity()).toList();
      });
}
