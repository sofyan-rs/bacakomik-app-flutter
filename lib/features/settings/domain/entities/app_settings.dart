import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_settings.freezed.dart';

/// App theme. Plain Dart so the domain layer stays free of Flutter.
enum AppThemeMode { system, light, dark }

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
    @Default(AppThemeMode.system) AppThemeMode themeMode,
    @Default(ReadingDirection.vertical) ReadingDirection readingDirection,
    @Default(PageFit.width) PageFit pageFit,

    /// Keep the screen awake while a chapter is open.
    @Default(true) bool keepScreenOn,

    /// 8px gap between pages.
    @Default(false) bool pageGap,
  }) = _AppSettings;
}
