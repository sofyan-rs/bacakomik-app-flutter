import 'package:bacakomik_app/core/storage/hive_boxes.dart';
import 'package:bacakomik_app/core/storage/json_box.dart';
import 'package:bacakomik_app/features/download/data/models/downloaded_chapter_model.dart';
import 'package:hive_ce/hive.dart';
import 'package:injectable/injectable.dart';

/// Download records in one box, the details of their comics in another (one
/// record per comic). The files themselves are in [DownloadFileDataSource].
abstract interface class DownloadLocalDataSource {
  List<DownloadedChapterModel> getChapters();

  DownloadedChapterModel? getChapter(String slug);

  Map<String, DownloadComicModel> getComics();

  DownloadComicModel? getComic(String comicSlug);

  Future<void> putChapters(List<DownloadedChapterModel> chapters);

  Future<void> putComic(DownloadComicModel comic);

  Future<void> deleteChapters(List<String> slugs);

  Future<void> deleteComics(List<String> comicSlugs);

  Future<void> clear();
}

@LazySingleton(as: DownloadLocalDataSource)
class DownloadLocalDataSourceImpl implements DownloadLocalDataSource {
  DownloadLocalDataSourceImpl(
    @Named(HiveBoxes.downloads) Box<String> chapters,
    @Named(HiveBoxes.downloadComics) Box<String> comics,
  ) : _chapters = JsonBox(
        chapters,
        fromJson: DownloadedChapterModel.fromJson,
        toJson: (c) => c.toJson(),
        keyOf: (c) => c.slug,
      ),
      _comics = JsonBox(
        comics,
        fromJson: DownloadComicModel.fromJson,
        toJson: (c) => c.toJson(),
        keyOf: (c) => c.slug,
      );

  final JsonBox<DownloadedChapterModel> _chapters;
  final JsonBox<DownloadComicModel> _comics;

  @override
  List<DownloadedChapterModel> getChapters() => _chapters.values();

  @override
  DownloadedChapterModel? getChapter(String slug) => _chapters.get(slug);

  @override
  Map<String, DownloadComicModel> getComics() => {
    for (final comic in _comics.values()) comic.slug: comic,
  };

  @override
  DownloadComicModel? getComic(String comicSlug) => _comics.get(comicSlug);

  @override
  Future<void> putChapters(List<DownloadedChapterModel> chapters) =>
      _chapters.putAll(chapters);

  @override
  Future<void> putComic(DownloadComicModel comic) => _comics.put(comic);

  @override
  Future<void> deleteChapters(List<String> slugs) => _chapters.deleteAll(slugs);

  @override
  Future<void> deleteComics(List<String> comicSlugs) =>
      _comics.deleteAll(comicSlugs);

  @override
  Future<void> clear() async {
    await _chapters.clear();
    await _comics.clear();
  }
}
