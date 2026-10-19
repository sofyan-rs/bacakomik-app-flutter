import 'package:bacakomik_app/core/di/injection.dart';
import 'package:bacakomik_app/core/network/api_client.dart';

/// Remote data source for bacakomik-api. Returns raw decoded JSON;
/// repositories map it into app models.
class BacaKomikDataProvider {
  BacaKomikDataProvider({ApiClient? client})
      : _client = client ?? getIt<ApiClient>();

  final ApiClient _client;

  Future<Map<String, dynamic>> getGenres() => _client.get('/genres');

  Future<Map<String, dynamic>> getSeriesList({
    int page = 1,
    int? limit,
    String? query,
    List<String> genres = const [],
    String? status,
    String? format,
    String? sort,
  }) =>
      _client.get('/series', query: {
        'page': page,
        'limit': limit,
        'q': query,
        'genre': genres.join(','),
        'status': status,
        'format': format,
        'sort': sort,
      });

  Future<Map<String, dynamic>> getCuratedList(
    String kind, {
    int page = 1,
    int? limit,
  }) =>
      _client.get('/lists/$kind', query: {'page': page, 'limit': limit});

  Future<Map<String, dynamic>> getSeries(String slug) =>
      _client.get('/series/$slug');

  Future<Map<String, dynamic>> getChapters(String slug) =>
      _client.get('/series/$slug/chapters');

  Future<Map<String, dynamic>> getChapter(String slug, String number) =>
      _client.get('/series/$slug/chapters/$number');
}
