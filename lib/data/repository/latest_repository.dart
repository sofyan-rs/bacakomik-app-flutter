import 'dart:convert';

import 'package:bacakomik_app/core/models/latest_model.dart';
import 'package:bacakomik_app/data/data_provider/latest_data_provider.dart';

class LatestRepository {
  final LatestDataProvider latestDataProvider;

  LatestRepository(this.latestDataProvider);

  Future<List<LatestModel>> getLatest(int page) async {
    try {
      final latestData = await latestDataProvider.getLatest(page);

      final data = jsonDecode(latestData);

      return List<LatestModel>.from(
        data['response']['data'].map(
          (e) => LatestModel.fromMap(e),
        ),
      );
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}
