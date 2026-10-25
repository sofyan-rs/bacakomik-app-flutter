/// One comic to add to the library from another app. Its key, title and
/// possibly its chapters are known; the cover and details load when the
/// user opens or refreshes it.
class ImportEntry {
  const ImportEntry({
    required this.key,
    required this.title,
    this.categories = const [],
    this.lastRead,
    this.chapters = const [],
  });

  /// Comic key in the target source.
  final String key;
  final String title;

  /// Category names; missing categories are created.
  final List<String> categories;

  /// Number of the last chapter read in the other app, when only that is
  /// known. Chapters up to it are marked read once the comic's chapter
  /// list loads.
  final String? lastRead;

  /// The comic's chapters in the other app, newest first, one per number.
  /// Empty when the other app does not tell.
  final List<ImportChapter> chapters;
}

/// A chapter of an [ImportEntry].
class ImportChapter {
  const ImportChapter({required this.number, this.uploaded, this.readDate});

  /// Chapter number as the app writes it: `14`, `10.5`.
  final String number;

  /// When the source released it.
  final DateTime? uploaded;

  /// When it was read; null while unread.
  final DateTime? readDate;

  bool get read => readDate != null;
}

/// What an import did.
class ImportResult {
  const ImportResult({
    required this.added,
    required this.existing,
    this.sameTitle = 0,
    this.chaptersRead = 0,
  });

  /// Comics added to the library.
  final int added;

  /// Comics already in the library. They keep their details; a comic
  /// never loaded gets the imported chapter list.
  final int existing;

  /// Series already bookmarked from another source; not added again.
  final int sameTitle;

  /// Chapters newly marked read.
  final int chaptersRead;
}
