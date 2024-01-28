import 'dart:convert';

import 'package:bacakomik_app/core/models/chapter_read_model.dart';
import 'package:bacakomik_app/data/data_provider/chapter_read_data_provider.dart';

class ChapterReadRepository {
  final ChapterReadDataProvider chapterReadDataProvider;

  ChapterReadRepository(this.chapterReadDataProvider);

  Future<ChapterReadModel> getChapterRead(String slug) async {
    try {
      final latestData = await chapterReadDataProvider.getChapterRead(slug);

      final data = jsonDecode(latestData);

      return ChapterReadModel.fromMap(data['response']['data']);
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}
