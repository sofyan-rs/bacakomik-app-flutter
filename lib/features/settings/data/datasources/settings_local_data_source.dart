import 'package:bacakomik_app/core/storage/hive_boxes.dart';
import 'package:bacakomik_app/core/storage/json_box.dart';
import 'package:bacakomik_app/features/settings/data/models/settings_model.dart';
import 'package:hive_ce/hive.dart';
import 'package:injectable/injectable.dart';

abstract interface class SettingsLocalDataSource {
  SettingsModel? get();

  Future<void> put(SettingsModel settings);
}

@LazySingleton(as: SettingsLocalDataSource)
class SettingsLocalDataSourceImpl implements SettingsLocalDataSource {
  SettingsLocalDataSourceImpl(@Named(HiveBoxes.settings) Box<String> box)
      : _box = JsonBox(
          box,
          fromJson: SettingsModel.fromJson,
          toJson: (s) => s.toJson(),
          keyOf: (_) => key,
        );

  /// Settings are a single record.
  static const key = 'settings';

  final JsonBox<SettingsModel> _box;

  @override
  SettingsModel? get() => _box.get(key);

  @override
  Future<void> put(SettingsModel settings) => _box.put(settings);
}
