import 'package:bacakomik_app/core/models/comic_model.dart';
import 'package:bacakomik_app/data/data_provider/bacakomik_data_provider.dart';

class SearchRepository {
  final BacaKomikDataProvider dataProvider;

  SearchRepository(this.dataProvider);

  Future<List<ComicModel>> getSearchResult(String keyword, int page) async {
    final res = await dataProvider.getSeriesList(query: keyword, page: page);
    return ComicModel.listFromApi(res);
  }
}
