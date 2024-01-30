import 'package:dio/dio.dart';
import 'package:bacakomik_app/core/constants/variables.dart';

final dio = Dio();

class LatestDataProvider {
  Future<String> getLatest(int page) async {
    try {
      final res = await dio.get('${AppVariables.baseUrl}/komik-updates/$page');

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
