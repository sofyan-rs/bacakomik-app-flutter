import 'package:bacakomik_app/core/storage/box_recovery.dart';
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

/// Opens every box before the app starts (`@preResolve`). The generated
/// code awaits the boxes one by one; the first one asked for starts opening
/// all of them at once, so the file reads overlap instead of queueing.
@module
abstract class StorageModule {
  /// Every box of [HiveBoxes], opening in parallel; one future per module
  /// (per `configureDependencies` call).
  late final Future<Map<String, Box<String>>> _boxes = () async {
    final boxes = await Future.wait([for (final n in _names) openStringBox(n)]);
    return {for (final (i, name) in _names.indexed) name: boxes[i]};
  }();

  /// Names of the boxes opened at startup.
  static const _names = [
    HiveBoxes.bookmarks,
    HiveBoxes.historyEntries,
    HiveBoxes.historyComics,
    HiveBoxes.downloads,
    HiveBoxes.downloadComics,
    HiveBoxes.categories,
    HiveBoxes.comicCategories,
    HiveBoxes.libraryDeletions,
    HiveBoxes.sync,
    HiveBoxes.extensions,
    HiveBoxes.extensionStorage,
    HiveBoxes.sourceSettings,
    HiveBoxes.pendingReads,
    HiveBoxes.settings,
  ];

  Future<Box<String>> _open(String name) async => (await _boxes)[name]!;

  @preResolve
  @Named(HiveBoxes.bookmarks)
  Future<Box<String>> get bookmarksBox => _open(HiveBoxes.bookmarks);

  @preResolve
  @Named(HiveBoxes.historyEntries)
  Future<Box<String>> get historyEntriesBox => _open(HiveBoxes.historyEntries);

  @preResolve
  @Named(HiveBoxes.historyComics)
  Future<Box<String>> get historyComicsBox => _open(HiveBoxes.historyComics);

  @preResolve
  @Named(HiveBoxes.downloads)
  Future<Box<String>> get downloadsBox => _open(HiveBoxes.downloads);

  @preResolve
  @Named(HiveBoxes.downloadComics)
  Future<Box<String>> get downloadComicsBox => _open(HiveBoxes.downloadComics);

  @preResolve
  @Named(HiveBoxes.categories)
  Future<Box<String>> get categoriesBox => _open(HiveBoxes.categories);

  @preResolve
  @Named(HiveBoxes.comicCategories)
  Future<Box<String>> get comicCategoriesBox =>
      _open(HiveBoxes.comicCategories);

  @preResolve
  @Named(HiveBoxes.libraryDeletions)
  Future<Box<String>> get libraryDeletionsBox =>
      _open(HiveBoxes.libraryDeletions);

  @preResolve
  @Named(HiveBoxes.sync)
  Future<Box<String>> get syncBox => _open(HiveBoxes.sync);

  @preResolve
  @Named(HiveBoxes.extensions)
  Future<Box<String>> get extensionsBox => _open(HiveBoxes.extensions);

  @preResolve
  @Named(HiveBoxes.extensionStorage)
  Future<Box<String>> get extensionStorageBox =>
      _open(HiveBoxes.extensionStorage);

  @preResolve
  @Named(HiveBoxes.sourceSettings)
  Future<Box<String>> get sourceSettingsBox => _open(HiveBoxes.sourceSettings);

  @preResolve
  @Named(HiveBoxes.pendingReads)
  Future<Box<String>> get pendingReadsBox => _open(HiveBoxes.pendingReads);

  @preResolve
  @Named(HiveBoxes.settings)
  Future<Box<String>> get settingsBox => _open(HiveBoxes.settings);
}
