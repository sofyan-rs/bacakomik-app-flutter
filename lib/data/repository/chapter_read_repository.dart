import 'package:bacakomik_app/core/models/chapter_read_model.dart';
import 'package:bacakomik_app/data/data_provider/bacakomik_data_provider.dart';

class ChapterReadRepository {
  final BacaKomikDataProvider dataProvider;

  ChapterReadRepository(this.dataProvider);

  /// [slug] is a chapter slug in the form `seriesSlug/number`.
  Future<ChapterReadModel> getChapterRead(String slug) async {
    final separator = slug.lastIndexOf('/');
    if (separator <= 0) {
      throw Exception('Chapter tidak valid: $slug');
    }
    final seriesSlug = slug.substring(0, separator);
    final number = slug.substring(separator + 1);

    final res = await dataProvider.getChapter(seriesSlug, number);
    return ChapterReadModel.fromApi(
      res['data'] as Map<String, dynamic>,
      seriesSlug,
    );
  }
}
