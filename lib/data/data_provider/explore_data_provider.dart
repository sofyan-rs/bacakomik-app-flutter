import 'package:dio/dio.dart';
import 'package:bacakomik_app/core/constants/variables.dart';

final dio = Dio();

class ExploreDataProvider {
  Future<String> getResult(String sortby, String status, String type,
      List<String> genres, int page) async {
    try {
      final res = await dio.get(
        '${AppVariables.baseUrl}/komik-list',
        queryParameters: {
          'sortby': sortby,
          'status': status == 'all' ? '' : status,
          'type': type == 'all' ? '' : type,
          'genres': genres.isNotEmpty ? genres : '',
          'page': page,
        },
      );

      if (res.statusCode == 200) {
        return res.toString();
      } else {
        throw Exception('Error: ${res.statusCode}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}
