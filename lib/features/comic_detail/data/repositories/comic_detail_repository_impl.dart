import 'package:bacakomik_app/core/data/datasources/series_remote_data_source.dart';
import 'package:bacakomik_app/core/domain/entities/comic_details.dart';
import 'package:bacakomik_app/core/error/failures.dart';
import 'package:bacakomik_app/core/network/network_info.dart';
import 'package:bacakomik_app/core/network/remote_call.dart';
import 'package:bacakomik_app/features/comic_detail/domain/repositories/comic_detail_repository.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: ComicDetailRepository)
class ComicDetailRepositoryImpl implements ComicDetailRepository {
  const ComicDetailRepositoryImpl(this._remote, this._networkInfo);

  final SeriesRemoteDataSource _remote;
  final NetworkInfo _networkInfo;

  @override
  Future<Either<Failure, ComicDetails>> getComicDetails(String slug) =>
      runRemote(_networkInfo, () async {
        final series = _remote.getSeries(slug);
        final chapters = _remote.getChapters(slug);
        // Fail fast with the first error while both requests run in parallel.
        await Future.wait([series, chapters]);
        return (await series).toEntity(await chapters);
      });
}
