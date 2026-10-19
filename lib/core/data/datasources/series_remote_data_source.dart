import 'package:bacakomik_app/core/data/models/series_response.dart';
import 'package:bacakomik_app/core/network/api_client.dart';
import 'package:injectable/injectable.dart';

/// bacakomik-api endpoints shared by the comic features.
abstract interface class SeriesRemoteDataSource {
  Future<List<SeriesResponse>> getSeriesList({
    int page = 1,
    int? limit,
    String? query,
    List<String> genres = const [],
    String? status,
    String? format,
    String? sort,
  });

  Future<List<SeriesResponse>> getCuratedList(
    String kind, {
    int page = 1,
    int? limit,
  });

  Future<SeriesDetailResponse> getSeries(String slug);

  Future<List<ChapterResponse>> getChapters(String slug);

  Future<ChapterDetailResponse> getChapter(String slug, String number);
}

@LazySingleton(as: SeriesRemoteDataSource)
class SeriesRemoteDataSourceImpl implements SeriesRemoteDataSource {
  SeriesRemoteDataSourceImpl(this._client);

  final ApiClient _client;

  @override
  Future<List<SeriesResponse>> getSeriesList({
    int page = 1,
    int? limit,
    String? query,
    List<String> genres = const [],
    String? status,
    String? format,
    String? sort,
  }) async {
    final res = await _client.get('/series', query: {
      'page': page,
      'limit': limit,
      'q': query,
      'genre': genres.join(','),
      'status': status,
      'format': format,
      'sort': sort,
    });
    return _seriesList(res);
  }

  @override
  Future<List<SeriesResponse>> getCuratedList(
    String kind, {
    int page = 1,
    int? limit,
  }) async {
    final res = await _client
        .get('/lists/$kind', query: {'page': page, 'limit': limit});
    return _seriesList(res);
  }

  @override
  Future<SeriesDetailResponse> getSeries(String slug) async {
    final res = await _client.get('/series/$slug');
    return SeriesDetailResponse.fromJson(res['data'] as Map<String, dynamic>);
  }

  @override
  Future<List<ChapterResponse>> getChapters(String slug) async {
    final res = await _client.get('/series/$slug/chapters');
    return (res['data'] as List)
        .map((e) => ChapterResponse.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<ChapterDetailResponse> getChapter(String slug, String number) async {
    final res = await _client.get('/series/$slug/chapters/$number');
    return ChapterDetailResponse.fromJson(res['data'] as Map<String, dynamic>);
  }

  List<SeriesResponse> _seriesList(Map<String, dynamic> res) =>
      (res['data'] as List)
          .map((e) => SeriesResponse.fromJson(e as Map<String, dynamic>))
          .toList();
}
