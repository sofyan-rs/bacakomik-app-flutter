import 'package:dio/dio.dart';
import 'package:bacakomik_app/core/constants/variables.dart';

final dio = Dio();

class ComicDetailsDataProvider {
  Future<String> getComicDetails(String slug) async {
    try {
      final res = await dio.get('${AppVariables.baseUrl}/komik/$slug');

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
