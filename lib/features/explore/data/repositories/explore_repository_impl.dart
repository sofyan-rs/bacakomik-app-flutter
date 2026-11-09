import 'package:yoru/core/data/datasources/series_remote_data_source.dart';
import 'package:yoru/core/domain/entities/comic.dart';
import 'package:yoru/core/error/failures.dart';
import 'package:yoru/core/network/network_info.dart';
import 'package:yoru/core/network/remote_call.dart';
import 'package:yoru/features/explore/domain/entities/explore_filter.dart';
import 'package:yoru/features/explore/domain/repositories/explore_repository.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: ExploreRepository)
class ExploreRepositoryImpl implements ExploreRepository {
  const ExploreRepositoryImpl(this._remote, this._networkInfo);

  final SeriesRemoteDataSource _remote;
  final NetworkInfo _networkInfo;

  @override
  Future<Either<Failure, List<Comic>>> explore(
    ExploreFilter filter,
    int page,
  ) => runRemote(_networkInfo, () async {
    final res = await _remote.getSeriesList(
      filter.source,
      query: filter.query.trim().isEmpty ? null : filter.query.trim(),
      filters: filter.values,
      page: page,
    );
    return res.map((e) => e.toEntity()).toList();
  });
}
