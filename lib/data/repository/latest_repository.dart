import 'package:bacakomik_app/core/models/comic_model.dart';
import 'package:bacakomik_app/data/data_provider/bacakomik_data_provider.dart';

class LatestRepository {
  final BacaKomikDataProvider dataProvider;

  LatestRepository(this.dataProvider);

  Future<List<ComicModel>> getLatest(int page) async {
    final res = await dataProvider.getSeriesList(sort: 'latest', page: page);
    return ComicModel.listFromApi(res);
  }
}
