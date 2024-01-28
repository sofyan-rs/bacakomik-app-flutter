import 'package:http/http.dart' as http;
import 'package:bacakomik_app/core/constants/variables.dart';

class ChapterReadDataProvider {
  Future<String> getChapterRead(String slug) async {
    try {
      final res = await http.get(
        Uri.parse('${AppVariables.baseUrl}/chapter/$slug'),
      );

      if (res.statusCode == 200) {
        return res.body;
      } else {
        throw Exception('Error: ${res.statusCode}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}
