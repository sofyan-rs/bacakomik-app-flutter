import 'package:bacakomik_app/core/data/models/comic_details_model.dart';
import 'package:bacakomik_app/features/download/domain/entities/downloaded_chapter.dart';
import 'package:json_annotation/json_annotation.dart';

part 'downloaded_chapter_model.g.dart';

/// Stored download of one chapter. File paths are relative to the
/// downloads folder, which can move between app updates on iOS.
@JsonSerializable()
class DownloadedChapterModel {
  const DownloadedChapterModel({
    required this.slug,
    required this.comicSlug,
    required this.chapterNumber,
    required this.addedAt,
    this.status = DownloadStatus.queued,
    this.chapterTitle,
    this.previousChapterSlug,
    this.nextChapterSlug,
    this.pageCount = 0,
    this.pages = const [],
    this.planned = const [],
    this.sizeBytes = 0,
    this.downloadedAt,
  });

  factory DownloadedChapterModel.fromJson(Map<String, dynamic> json) =>
      _$DownloadedChapterModelFromJson(json);

  /// Chapter slug (`seriesSlug/number`).
  final String slug;
  final String comicSlug;
  final String chapterNumber;
  @EpochMillisConverter()
  final DateTime addedAt;
  @JsonKey(unknownEnumValue: DownloadStatus.failed)
  final DownloadStatus status;
  final String? chapterTitle;
  final String? previousChapterSlug;
  final String? nextChapterSlug;

  /// Pages in the chapter; 0 until the page list has been fetched.
  final int pageCount;

  /// Saved pages, in page order. Named by 0-based page index (`007.webp`).
  final List<String> pages;

  /// Every page's path, by index, once the page list is known. Pages
  /// saved while the app was not running are found by checking these.
  final List<String> planned;
  final int sizeBytes;
  @EpochMillisConverter()
  final DateTime? downloadedAt;

  Map<String, dynamic> toJson() => _$DownloadedChapterModelToJson(this);

  DownloadedChapterModel copyWith({
    DownloadStatus? status,
    String? chapterTitle,
    String? previousChapterSlug,
    String? nextChapterSlug,
    int? pageCount,
    List<String>? pages,
    List<String>? planned,
    int? sizeBytes,
    DateTime? downloadedAt,
  }) => DownloadedChapterModel(
    slug: slug,
    comicSlug: comicSlug,
    chapterNumber: chapterNumber,
    addedAt: addedAt,
    status: status ?? this.status,
    chapterTitle: chapterTitle ?? this.chapterTitle,
    previousChapterSlug: previousChapterSlug ?? this.previousChapterSlug,
    nextChapterSlug: nextChapterSlug ?? this.nextChapterSlug,
    pageCount: pageCount ?? this.pageCount,
    pages: pages ?? this.pages,
    planned: planned ?? this.planned,
    sizeBytes: sizeBytes ?? this.sizeBytes,
    downloadedAt: downloadedAt ?? this.downloadedAt,
  );

  DownloadedChapter toEntity() => DownloadedChapter(
    slug: slug,
    comicSlug: comicSlug,
    chapterNumber: chapterNumber,
    status: status,
    addedAt: addedAt,
    pageCount: pageCount,
    savedPages: pages.length,
    sizeBytes: sizeBytes,
    downloadedAt: downloadedAt,
  );
}

/// Details of a comic with downloads, keyed by the series slug. Lets the
/// comic page open offline.
@JsonSerializable()
class DownloadComicModel {
  const DownloadComicModel({
    required this.slug,
    required this.comicDetails,
    this.cover,
  });

  factory DownloadComicModel.fromJson(Map<String, dynamic> json) =>
      _$DownloadComicModelFromJson(json);

  /// Series slug.
  final String slug;
  final ComicDetailsModel comicDetails;

  /// Saved cover, relative to the downloads folder.
  final String? cover;

  Map<String, dynamic> toJson() => _$DownloadComicModelToJson(this);
}
