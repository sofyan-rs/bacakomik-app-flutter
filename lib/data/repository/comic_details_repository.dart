import 'package:bacakomik_app/core/models/comic_details_model/comic_details_model.dart';
import 'package:bacakomik_app/data/data_provider/bacakomik_data_provider.dart';

class ComicDetailsRepository {
  final BacaKomikDataProvider dataProvider;

  ComicDetailsRepository(this.dataProvider);

  Future<ComicDetailsModel> getComicDetails(String slug) async {
    final results = await Future.wait([
      dataProvider.getSeries(slug),
      dataProvider.getChapters(slug),
    ]);

    return ComicDetailsModel.fromApi(
      results[0]['data'] as Map<String, dynamic>,
      results[1]['data'] as List<dynamic>,
    );
  }
}
