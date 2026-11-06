import 'package:bacakomik_app/core/data/models/series_response.dart';
import 'package:bacakomik_app/core/error/exceptions.dart';
import 'package:bacakomik_app/core/source/comic_key.dart';
import 'package:bacakomik_app/core/source/extension_manager.dart';
import 'package:bacakomik_app/core/source/extension_meta.dart';
import 'package:bacakomik_app/core/source/extension_runtime.dart';
import 'package:bacakomik_app/core/utils/cover_url.dart';
import 'package:injectable/injectable.dart';

/// Comic data from the installed sources. Series are addressed by
/// [ComicKey]; slugs in the returned models are keys too, so callers never
/// deal with source ids except when listing.
abstract interface class SeriesRemoteDataSource {
  /// [filters] holds values per filter group of the source; groups left
  /// out use their defaults.
  Future<List<SeriesResponse>> getSeriesList(
    String sourceId, {
    int page = 1,
    int? limit,
    String? query,
    FilterValues filters = const {},
  });

  Future<SeriesDetailResponse> getSeries(String key);

  Future<List<ChapterResponse>> getChapters(String key);

  Future<ChapterDetailResponse> getChapter(String key, String number);
}

@LazySingleton(as: SeriesRemoteDataSource)
class SeriesRemoteDataSourceImpl implements SeriesRemoteDataSource {
  SeriesRemoteDataSourceImpl(this._sources);

  final SourceRegistry _sources;

  @override
  Future<List<SeriesResponse>> getSeriesList(
    String sourceId, {
    int page = 1,
    int? limit,
    String? query,
    FilterValues filters = const {},
  }) async {
    final backend = await _sources.backend(sourceId);
    final res = _map(
      await backend.call('browse', [
        {
          'page': page,
          'limit': limit ?? 30,
          'query': query,
          'filters': filters,
        },
      ]),
    );
    return [
      for (final item in _list(res['items']))
        _withCover(
          SeriesResponse.fromJson(item),
          backend,
        ).copyWith(slug: ComicKey.of(sourceId, '${item['slug']}')),
    ];
  }

  @override
  Future<SeriesDetailResponse> getSeries(String key) async {
    final backend = await _sources.backend(ComicKey.sourceOf(key));
    final res = _map(await backend.call('series', [ComicKey.slugOf(key)]));
    final series = SeriesDetailResponse.fromJson(res);
    return series.copyWith(slug: key, cover: _absolute(series.cover, backend));
  }

  static SeriesResponse _withCover(SeriesResponse s, SourceBackend backend) =>
      s.copyWith(cover: _absolute(s.cover, backend));

  /// A cover given as a path on the site, against the source's base URL.
  static String? _absolute(String? cover, SourceBackend backend) =>
      cover != null && backend is LoadedSource
      ? absoluteCover(cover, backend.meta.baseUrl)
      : cover;

  @override
  Future<List<ChapterResponse>> getChapters(String key) async {
    final res = await _call(ComicKey.sourceOf(key), 'chapters', [
      ComicKey.slugOf(key),
    ]);
    return _list(res).map(ChapterResponse.fromJson).toList();
  }

  @override
  Future<ChapterDetailResponse> getChapter(String key, String number) async {
    final res = await _call(ComicKey.sourceOf(key), 'chapter', [
      ComicKey.slugOf(key),
      num.tryParse(number) ?? number,
    ]);
    return ChapterDetailResponse.fromJson(_map(res));
  }

  Future<Object?> _call(
    String sourceId,
    String method,
    List<Object?> args,
  ) async {
    final backend = await _sources.backend(sourceId);
    return backend.call(method, args);
  }

  static Map<String, dynamic> _map(Object? value) {
    if (value is Map) return value.cast<String, dynamic>();
    throw const ServerException('Source returned an unexpected response');
  }

  static List<Map<String, dynamic>> _list(Object? value) {
    if (value is List) {
      return [
        for (final e in value)
          if (e is Map) e.cast<String, dynamic>(),
      ];
    }
    throw const ServerException('Source returned an unexpected response');
  }
}
