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

/// What the tabs on the Bookmarks screen split bookmarks by.
enum BookmarkGrouping {
  /// All / Updated / Completed.
  status,

  /// One tab per source.
  source,

  /// One tab per user category, plus Uncategorized.
  category,
}

/// What the Bookmarks list is ordered by.
enum BookmarkSort {
  /// `Bookmark.updatedDate`: when added or new chapters were found. The
  /// order bookmarks had before sorting was added.
  updated,

  /// Title, case ignored.
  title,

  /// Number of chapters.
  chapters,

  /// Release date of the newest chapter.
  latestChapter,

  /// When the comic was bookmarked.
  added,

  /// When a chapter of the comic was last read.
  lastRead,

  /// Chapters not read yet, the count badge.
  unread,
}

enum SortDirection { ascending, descending }

/// Auto-scroll speed levels; each level scrolls [autoScrollStep] px/s.
const autoScrollMin = 1;
const autoScrollMax = 10;
const autoScrollStep = 40.0;

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

    /// Thin page progress line at the bottom while the controls are hidden.
    @Default(true) bool progressBar,

    /// Auto-scroll speed level, [autoScrollMin] to [autoScrollMax].
    @Default(3) int autoScrollSpeed,

    /// Incognito mode: the reader records no history.
    @Default(false) bool incognito,
    @Default(BookmarkGrouping.status) BookmarkGrouping bookmarkGrouping,
    @Default(BookmarkSort.updated) BookmarkSort bookmarkSort,
    @Default(SortDirection.descending) SortDirection bookmarkSortDirection,
  }) = _AppSettings;
}
