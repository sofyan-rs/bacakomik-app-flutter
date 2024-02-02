import 'dart:convert';

import 'package:bacakomik_app/core/models/comic_list_model.dart';
import 'package:bacakomik_app/data/data_provider/comic_list_data_provider.dart';

class ComicListRepository {
  final ComicListDataProvider comicListDataProvider;

  ComicListRepository(this.comicListDataProvider);

  Future<List<ComicListModel>> getAllComic() async {
    try {
      final comicListData = await comicListDataProvider.getAllComic();

      final data = jsonDecode(comicListData);

      return List<ComicListModel>.from(
        data['data'].map(
          (e) => ComicListModel.fromMap(e),
        ),
      );
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}
