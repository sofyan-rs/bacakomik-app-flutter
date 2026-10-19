import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_settings.freezed.dart';

/// How chapter pages are laid out in the reader.
enum ReadingDirection {
  /// One long vertical strip.
  vertical,

  /// One page at a time, swipe from right to left (manga).
  rightToLeft,

  /// One page at a time, swipe from left to right.
  leftToRight,
}

/// How a page is scaled in the reader.
enum PageFit { width, height }

@freezed
abstract class AppSettings with _$AppSettings {
  const factory AppSettings({
    /// One of [AppText.system], [AppText.light] or [AppText.dark].
    @Default(AppText.system) String darkMode,
    @Default(ReadingDirection.vertical) ReadingDirection readingDirection,
    @Default(PageFit.width) PageFit pageFit,

    /// Keep the screen awake while a chapter is open.
    @Default(true) bool keepScreenOn,

    /// 8px gap between pages.
    @Default(false) bool pageGap,
  }) = _AppSettings;
}
