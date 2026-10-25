/// One comic to add to the library from another app. Only its key and
/// title are known; the details load when the user opens or refreshes it.
class ImportEntry {
  const ImportEntry({
    required this.key,
    required this.title,
    this.categories = const [],
    this.lastRead,
  });

  /// Comic key in the target source.
  final String key;
  final String title;

  /// Category names; missing categories are created.
  final List<String> categories;

  /// Number of the last chapter read in the other app. Chapters up to it
  /// are marked read once the comic's chapter list loads.
  final String? lastRead;
}

/// What an import did.
class ImportResult {
  const ImportResult({required this.added, required this.existing});

  /// Comics added to the library.
  final int added;

  /// Comics already in the library, left as they were.
  final int existing;
}
