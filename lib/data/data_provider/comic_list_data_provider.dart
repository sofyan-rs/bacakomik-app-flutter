import 'package:dio/dio.dart';
import 'package:bacakomik_app/core/constants/variables.dart';

final dio = Dio();

class ComicListDataProvider {
  Future<String> getAllComic() async {
    try {
      final res = await dio.get('${AppVariables.baseUrl}/all-komik');

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
