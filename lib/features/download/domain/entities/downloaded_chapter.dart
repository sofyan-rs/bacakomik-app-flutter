import 'package:freezed_annotation/freezed_annotation.dart';

part 'downloaded_chapter.freezed.dart';

enum DownloadStatus {
  queued,
  downloading,
  completed,

  /// Stopped by an error or by the app closing. Saved pages are kept, so a
  /// retry only fetches the rest.
  failed,
}

@freezed
abstract class DownloadedChapter with _$DownloadedChapter {
  const DownloadedChapter._();

  const factory DownloadedChapter({
    /// Chapter slug (`seriesSlug/number`).
    required String slug,
    required String comicSlug,
    required String chapterNumber,
    required DownloadStatus status,

    /// When the chapter was added to the queue; orders the queue.
    required DateTime addedAt,

    /// 0 until the chapter's page list has been fetched.
    @Default(0) int pageCount,
    @Default(0) int savedPages,
    @Default(0) int sizeBytes,
    DateTime? downloadedAt,
  }) = _DownloadedChapter;

  bool get isCompleted => status == DownloadStatus.completed;

  /// Queued, downloading or failed: shown in the queue, not readable offline.
  bool get isPending => !isCompleted;
}
