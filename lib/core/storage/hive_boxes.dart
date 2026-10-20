import 'package:hive_ce/hive.dart';
import 'package:injectable/injectable.dart';

/// Hive box names. Every box stores JSON-encoded strings keyed by id.
abstract final class HiveBoxes {
  static const bookmarks = 'bookmarks';
  static const settings = 'settings';

  /// Read chapters, keyed by chapter slug.
  static const historyEntries = 'history_entries';

  /// Details of comics in the history, keyed by series slug.
  static const historyComics = 'history_comics';

  /// Downloaded chapters, keyed by chapter slug.
  static const downloads = 'downloads';

  /// Details of comics with downloads, keyed by series slug.
  static const downloadComics = 'download_comics';
}

@module
abstract class StorageModule {
  @preResolve
  @Named(HiveBoxes.bookmarks)
  Future<Box<String>> get bookmarksBox =>
      Hive.openBox<String>(HiveBoxes.bookmarks);

  @preResolve
  @Named(HiveBoxes.historyEntries)
  Future<Box<String>> get historyEntriesBox =>
      Hive.openBox<String>(HiveBoxes.historyEntries);

  @preResolve
  @Named(HiveBoxes.historyComics)
  Future<Box<String>> get historyComicsBox =>
      Hive.openBox<String>(HiveBoxes.historyComics);

  @preResolve
  @Named(HiveBoxes.downloads)
  Future<Box<String>> get downloadsBox =>
      Hive.openBox<String>(HiveBoxes.downloads);

  @preResolve
  @Named(HiveBoxes.downloadComics)
  Future<Box<String>> get downloadComicsBox =>
      Hive.openBox<String>(HiveBoxes.downloadComics);

  @preResolve
  @Named(HiveBoxes.settings)
  Future<Box<String>> get settingsBox =>
      Hive.openBox<String>(HiveBoxes.settings);
}
