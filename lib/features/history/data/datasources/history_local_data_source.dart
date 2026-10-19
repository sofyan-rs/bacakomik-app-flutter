import 'package:bacakomik_app/core/storage/hive_boxes.dart';
import 'package:bacakomik_app/core/storage/json_box.dart';
import 'package:bacakomik_app/features/history/data/models/read_history_model.dart';
import 'package:hive_ce/hive.dart';
import 'package:injectable/injectable.dart';

/// Read chapters in one box, the details of their comics in another (one
/// record per comic).
abstract interface class HistoryLocalDataSource {
  List<ReadHistoryModel> getEntries();

  Map<String, HistoryComicModel> getComics();

  Future<void> putEntries(List<ReadHistoryModel> entries);

  Future<void> putComics(List<HistoryComicModel> comics);

  Future<void> deleteEntries(List<String> slugs);

  Future<void> deleteComics(List<String> comicSlugs);

  Future<void> clear();
}

@LazySingleton(as: HistoryLocalDataSource)
class HistoryLocalDataSourceImpl implements HistoryLocalDataSource {
  HistoryLocalDataSourceImpl(
    @Named(HiveBoxes.historyEntries) Box<String> entries,
    @Named(HiveBoxes.historyComics) Box<String> comics,
  ) : _entries = JsonBox(
        entries,
        fromJson: ReadHistoryModel.fromJson,
        toJson: (h) => h.toJson(),
        keyOf: (h) => h.slug,
      ),
      _comics = JsonBox(
        comics,
        fromJson: HistoryComicModel.fromJson,
        toJson: (c) => c.toJson(),
        keyOf: (c) => c.slug,
      );

  final JsonBox<ReadHistoryModel> _entries;
  final JsonBox<HistoryComicModel> _comics;

  @override
  List<ReadHistoryModel> getEntries() => _entries.values();

  @override
  Map<String, HistoryComicModel> getComics() => {
    for (final comic in _comics.values()) comic.slug: comic,
  };

  @override
  Future<void> putEntries(List<ReadHistoryModel> entries) =>
      _entries.putAll(entries);

  @override
  Future<void> putComics(List<HistoryComicModel> comics) =>
      _comics.putAll(comics);

  @override
  Future<void> deleteEntries(List<String> slugs) => _entries.deleteAll(slugs);

  @override
  Future<void> deleteComics(List<String> comicSlugs) =>
      _comics.deleteAll(comicSlugs);

  @override
  Future<void> clear() async {
    await _entries.clear();
    await _comics.clear();
  }
}
