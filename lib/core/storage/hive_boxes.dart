import 'package:hive_ce/hive.dart';
import 'package:injectable/injectable.dart';

/// Hive box names. Every box stores JSON-encoded strings keyed by id.
abstract final class HiveBoxes {
  static const bookmarks = 'bookmarks';
  static const history = 'history';
  static const settings = 'settings';
  static const meta = 'app_meta';

  /// Box written by hydrated_bloc in earlier app versions.
  static const legacyHydrated = 'hydrated_box';
}

@module
abstract class StorageModule {
  @preResolve
  @Named(HiveBoxes.bookmarks)
  Future<Box<String>> get bookmarksBox =>
      Hive.openBox<String>(HiveBoxes.bookmarks);

  @preResolve
  @Named(HiveBoxes.history)
  Future<Box<String>> get historyBox => Hive.openBox<String>(HiveBoxes.history);

  @preResolve
  @Named(HiveBoxes.settings)
  Future<Box<String>> get settingsBox =>
      Hive.openBox<String>(HiveBoxes.settings);

  @preResolve
  @Named(HiveBoxes.meta)
  Future<Box<String>> get metaBox => Hive.openBox<String>(HiveBoxes.meta);
}
