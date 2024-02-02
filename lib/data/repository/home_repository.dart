import 'dart:convert';

import 'package:bacakomik_app/core/models/home_model.dart';
import 'package:bacakomik_app/data/data_provider/home_data_provider.dart';

class HomeRepository {
  final HomeDataProvider homeProvider;

  HomeRepository(this.homeProvider);

  Future<HomeModel> getHome() async {
    try {
      final homeData = await homeProvider.getHome();

      final data = jsonDecode(homeData);

      return HomeModel.fromMap(data['data']);
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}
