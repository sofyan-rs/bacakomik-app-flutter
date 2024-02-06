import 'dart:convert';

import 'package:bacakomik_app/core/models/comic_model.dart';
import 'package:bacakomik_app/data/data_provider/explore_data_provider.dart';

class ExploreRepository {
  final ExploreDataProvider exploreDataProvider;

  ExploreRepository(this.exploreDataProvider);

  Future<List<ComicModel>> getResult(String sortby, String status, String type,
      List<String> genres, int page) async {
    try {
      final searchData = await exploreDataProvider.getResult(
        sortby,
        status,
        type,
        genres,
        page,
      );

      final data = jsonDecode(searchData);

      return List<ComicModel>.from(
        data['data'].map(
          (e) => ComicModel.fromMap(e),
        ),
      );
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}
