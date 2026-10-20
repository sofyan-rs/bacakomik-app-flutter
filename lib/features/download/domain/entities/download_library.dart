import 'package:bacakomik_app/core/domain/entities/comic_details.dart';
import 'package:bacakomik_app/features/download/domain/entities/downloaded_chapter.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'download_library.freezed.dart';

/// A comic with at least one downloaded or queued chapter.
@freezed
abstract class DownloadedComic with _$DownloadedComic {
  const factory DownloadedComic({
    required String slug,
    required ComicDetails comicDetails,

    /// Absolute path of the saved cover; null until it has been saved.
    String? coverPath,
  }) = _DownloadedComic;
}

/// Every download, with lookups for the screens.
@freezed
abstract class DownloadLibrary with _$DownloadLibrary {
  const DownloadLibrary._();

  const factory DownloadLibrary({
    @Default({}) Map<String, DownloadedChapter> chapters,
    @Default({}) Map<String, DownloadedComic> comics,
  }) = _DownloadLibrary;

  DownloadedChapter? chapter(String slug) => chapters[slug];

  /// Queued, downloading and failed chapters, in the order they were added.
  List<DownloadedChapter> get pending =>
      chapters.values.where((c) => c.isPending).toList()
        ..sort((a, b) => a.addedAt.compareTo(b.addedAt));

  /// Completed chapters per comic, comics by title and chapters by number.
  List<(DownloadedComic, List<DownloadedChapter>)> get completedByComic {
    final byComic = <String, List<DownloadedChapter>>{};
    for (final chapter in chapters.values) {
      if (chapter.isCompleted) {
        (byComic[chapter.comicSlug] ??= []).add(chapter);
      }
    }
    final groups = [
      for (final MapEntry(key: slug, value: list) in byComic.entries)
        if (comics[slug] case final comic?)
          (comic, list..sort((a, b) => _number(a).compareTo(_number(b)))),
    ];
    return groups..sort(
      (a, b) => a.$1.comicDetails.title.toLowerCase().compareTo(
        b.$1.comicDetails.title.toLowerCase(),
      ),
    );
  }

  int get completedCount => chapters.values.where((c) => c.isCompleted).length;

  /// Bytes on disk, partial downloads included.
  int get totalBytes =>
      chapters.values.fold(0, (sum, chapter) => sum + chapter.sizeBytes);

  static double _number(DownloadedChapter c) =>
      double.tryParse(c.chapterNumber) ?? double.infinity;
}
