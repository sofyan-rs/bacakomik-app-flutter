import 'package:freezed_annotation/freezed_annotation.dart';

part 'chapter_content.freezed.dart';

@freezed
abstract class ChapterContent with _$ChapterContent {
  const factory ChapterContent({
    required String chapterTitle,
    required String chapterNumber,
    required String seriesSlug,
    String? previousChapterSlug,
    String? nextChapterSlug,
    required List<String> images,

    /// True when [images] are file paths of a downloaded chapter.
    @Default(false) bool isOffline,
  }) = _ChapterContent;
}
