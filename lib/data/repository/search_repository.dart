import 'dart:convert';

import 'package:bacakomik_app/core/models/comic_model.dart';
import 'package:bacakomik_app/data/data_provider/search_data_provider.dart';

class SearchRepository {
  final SearchDataProvider searchDataProvider;

  SearchRepository(this.searchDataProvider);

  Future<List<ComicModel>> getSearchResult(String keyword, int page) async {
    try {
      final searchData =
          await searchDataProvider.getSearchResult(keyword, page);

      final data = jsonDecode(searchData);

      return List<ComicModel>.from(
        data['response']['data'].map(
          (e) => ComicModel.fromMap(e),
        ),
      );
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}
