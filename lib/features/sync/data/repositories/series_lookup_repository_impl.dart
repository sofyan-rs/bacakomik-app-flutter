import 'package:bacakomik_app/core/data/datasources/series_remote_data_source.dart';
import 'package:bacakomik_app/core/data/models/series_response.dart';
import 'package:bacakomik_app/core/domain/entities/comic_details.dart';
import 'package:bacakomik_app/core/error/exceptions.dart';
import 'package:bacakomik_app/core/error/failures.dart';
import 'package:bacakomik_app/core/network/network_info.dart';
import 'package:bacakomik_app/core/network/remote_call.dart';
import 'package:bacakomik_app/features/sync/domain/repositories/series_lookup_repository.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: SeriesLookupRepository)
class SeriesLookupRepositoryImpl implements SeriesLookupRepository {
  const SeriesLookupRepositoryImpl(this._remote, this._networkInfo);

  final SeriesRemoteDataSource _remote;
  final NetworkInfo _networkInfo;

  @override
  Future<Either<Failure, SeriesMatch?>> find(
    String slug,
    ComicDetails stored,
  ) => runRemote(_networkInfo, () async {
    // Slugs come from titles, so most comics keep theirs.
    var series = await _seriesOrNull(slug);
    if (series == null) {
      final title = _normalize(stored.title);
      if (title.isEmpty) return null;
      final results = await _remote.getSeriesList(
        query: stored.title,
        limit: 10,
      );
      final match = results
          .where((s) => _normalize(s.title) == title)
          .firstOrNull;
      if (match == null) return null;
      series = await _remote.getSeries(match.slug);
    }
    final chapters = await _remote.getChapters(series.slug);
    return (slug: series.slug, details: series.toEntity(chapters));
  });

  Future<SeriesDetailResponse?> _seriesOrNull(String slug) async {
    try {
      return await _remote.getSeries(slug);
    } on ServerException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  /// Ignores case, spacing and punctuation, which differ between sources
  /// (`’` and `'`, `:` and `-`).
  static String _normalize(String title) => title.toLowerCase().replaceAll(
    RegExp(r'[^\p{L}\p{N}]', unicode: true),
    '',
  );
}
