import 'package:bacakomik_app/core/data/datasources/series_remote_data_source.dart';
import 'package:bacakomik_app/core/domain/entities/comic.dart';
import 'package:bacakomik_app/core/domain/entities/comic_details.dart';
import 'package:bacakomik_app/core/error/failures.dart';
import 'package:bacakomik_app/core/network/network_info.dart';
import 'package:bacakomik_app/core/network/remote_call.dart';
import 'package:bacakomik_app/features/explore/domain/entities/explore_filter.dart';
import 'package:bacakomik_app/features/explore/domain/repositories/explore_repository.dart';
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
  ) =>
      runRemote(_networkInfo, () async {
        final res = await _remote.getSeriesList(
          query: filter.query.trim().isEmpty ? null : filter.query.trim(),
          sort: filter.sortBy == 'default' ? null : filter.sortBy,
          status: filter.status == 'all' ? null : filter.status,
          format: filter.type == 'all' ? null : filter.type,
          genres: filter.genres,
          page: page,
        );
        return res.map((e) => e.toEntity()).toList();
      });

  @override
  Future<Either<Failure, List<Genre>>> genres() => runRemote(
        _networkInfo,
        () async =>
            (await _remote.getGenres()).map((e) => e.toEntity()).toList(),
      );
}
