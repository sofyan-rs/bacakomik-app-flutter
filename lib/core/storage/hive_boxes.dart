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

  /// Bookmark categories, keyed by category id.
  static const categories = 'categories';

  /// Categories of each bookmarked comic, keyed by series slug.
  static const comicCategories = 'comic_categories';

  /// Deletion times of bookmarks, history entries and categories, keyed by
  /// `kind:slug`, so sync can remove them on other devices.
  static const libraryDeletions = 'library_deletions';

  /// Sync account state, e.g. the last successful sync.
  static const sync = 'sync';

  /// Installed extensions' metadata, keyed by extension id.
  static const extensions = 'extensions';

  /// Values extensions save through `storage.set`, keyed by `id:key`.
  static const extensionStorage = 'extension_storage';

  /// Extension repo URLs and the active source.
  static const sourceSettings = 'source_settings';

  /// Imported reading progress waiting for a comic's chapter list: the last
  /// read chapter number, keyed by series slug.
  static const pendingReads = 'pending_reads';
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
  @Named(HiveBoxes.categories)
  Future<Box<String>> get categoriesBox =>
      Hive.openBox<String>(HiveBoxes.categories);

  @preResolve
  @Named(HiveBoxes.comicCategories)
  Future<Box<String>> get comicCategoriesBox =>
      Hive.openBox<String>(HiveBoxes.comicCategories);

  @preResolve
  @Named(HiveBoxes.libraryDeletions)
  Future<Box<String>> get libraryDeletionsBox =>
      Hive.openBox<String>(HiveBoxes.libraryDeletions);

  @preResolve
  @Named(HiveBoxes.sync)
  Future<Box<String>> get syncBox => Hive.openBox<String>(HiveBoxes.sync);

  @preResolve
  @Named(HiveBoxes.extensions)
  Future<Box<String>> get extensionsBox =>
      Hive.openBox<String>(HiveBoxes.extensions);

  @preResolve
  @Named(HiveBoxes.extensionStorage)
  Future<Box<String>> get extensionStorageBox =>
      Hive.openBox<String>(HiveBoxes.extensionStorage);

  @preResolve
  @Named(HiveBoxes.sourceSettings)
  Future<Box<String>> get sourceSettingsBox =>
      Hive.openBox<String>(HiveBoxes.sourceSettings);

  @preResolve
  @Named(HiveBoxes.pendingReads)
  Future<Box<String>> get pendingReadsBox =>
      Hive.openBox<String>(HiveBoxes.pendingReads);

  @preResolve
  @Named(HiveBoxes.settings)
  Future<Box<String>> get settingsBox =>
      Hive.openBox<String>(HiveBoxes.settings);
}
