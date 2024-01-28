import 'package:http/http.dart' as http;
import 'package:bacakomik_app/core/constants/variables.dart';

class ComicDetailsDataProvider {
  Future<String> getComicDetails(String slug) async {
    try {
      final res = await http.get(
        Uri.parse('${AppVariables.baseUrl}/komik/$slug'),
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
