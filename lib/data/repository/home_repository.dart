import 'package:bacakomik_app/core/models/comic_model.dart';
import 'package:bacakomik_app/core/models/home_model.dart';
import 'package:bacakomik_app/core/models/popular_model.dart';
import 'package:bacakomik_app/data/data_provider/bacakomik_data_provider.dart';

class HomeRepository {
  final BacaKomikDataProvider dataProvider;

  HomeRepository(this.dataProvider);

  Future<HomeModel> getHome() async {
    final results = await Future.wait([
      dataProvider.getCuratedList('trending', limit: 10),
      dataProvider.getSeriesList(sort: 'latest', limit: 20),
    ]);

    return HomeModel(
      popular: (results[0]['data'] as List)
          .map((e) => PopularModel.fromApi(e as Map<String, dynamic>))
          .toList(),
      latest: (results[1]['data'] as List)
          .map((e) => ComicModel.fromApi(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
