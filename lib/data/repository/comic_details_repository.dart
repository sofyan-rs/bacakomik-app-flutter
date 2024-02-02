import 'dart:convert';

import 'package:bacakomik_app/core/models/comic_details_model/comic_details_model.dart';
import 'package:bacakomik_app/data/data_provider/comic_details_data_provider.dart';

class ComicDetailsRepository {
  final ComicDetailsDataProvider comicDetailsDataProvider;

  ComicDetailsRepository(this.comicDetailsDataProvider);

  Future<ComicDetailsModel> getComicDetails(String slug) async {
    try {
      final latestData = await comicDetailsDataProvider.getComicDetails(slug);

      final data = jsonDecode(latestData);

      return ComicDetailsModel.fromMap(data['data']);
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}
