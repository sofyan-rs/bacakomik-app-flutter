import 'package:bacakomik_app/core/storage/hive_boxes.dart';
import 'package:bacakomik_app/core/storage/json_box.dart';
import 'package:bacakomik_app/features/history/data/models/read_history_model.dart';
import 'package:hive_ce/hive.dart';
import 'package:injectable/injectable.dart';

abstract interface class HistoryLocalDataSource {
  List<ReadHistoryModel> getAll();

  Future<void> putAll(List<ReadHistoryModel> history);

  Future<void> deleteAll(List<String> slugs);

  Future<void> clear();
}

@LazySingleton(as: HistoryLocalDataSource)
class HistoryLocalDataSourceImpl implements HistoryLocalDataSource {
  HistoryLocalDataSourceImpl(@Named(HiveBoxes.history) Box<String> box)
      : _box = JsonBox(
          box,
          fromJson: ReadHistoryModel.fromJson,
          toJson: (h) => h.toJson(),
          keyOf: (h) => h.slug,
        );

  final JsonBox<ReadHistoryModel> _box;

  @override
  List<ReadHistoryModel> getAll() => _box.values();

  @override
  Future<void> putAll(List<ReadHistoryModel> history) => _box.putAll(history);

  @override
  Future<void> deleteAll(List<String> slugs) => _box.deleteAll(slugs);

  @override
  Future<void> clear() => _box.clear();
}
