import 'package:bacakomik_app/core/models/comic_model.dart';
import 'package:bacakomik_app/data/data_provider/bacakomik_data_provider.dart';

class ExploreRepository {
  final BacaKomikDataProvider dataProvider;

  ExploreRepository(this.dataProvider);

  Future<List<ComicModel>> getResult(String sortby, String status, String type,
      List<String> genres, int page) async {
    final res = await dataProvider.getSeriesList(
      sort: sortby == 'default' ? null : sortby,
      status: status == 'all' ? null : status,
      format: type == 'all' ? null : type,
      genres: genres,
      page: page,
    );
    return ComicModel.listFromApi(res);
  }
}
