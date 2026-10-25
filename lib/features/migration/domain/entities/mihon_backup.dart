/// What the app reads from a Mihon/Tachiyomi backup (`.tachibk`): each
/// comic's source, link and title, and the category names. Chapters,
/// covers and history are left out; the comic's source loads them later.
class MihonBackup {
  const MihonBackup({
    required this.manga,
    required this.sourceNames,
    required this.categories,
  });

  final List<MihonManga> manga;

  /// Source name by Mihon source id, e.g. `MangaDex`.
  final Map<int, String> sourceNames;

  /// Category name by its order; [MihonManga.categories] holds orders.
  final Map<int, String> categories;
}

class MihonManga {
  const MihonManga({
    required this.sourceId,
    required this.url,
    required this.title,
    this.favorite = true,
    this.categories = const [],
  });

  /// Mihon source id: a hash of the source's name, language and version.
  final int sourceId;

  /// Series link relative to the source's site, e.g. `/manga/<slug>/`.
  final String url;
  final String title;

  /// In the library. Comics that are only in the history are not.
  final bool favorite;

  /// Orders of the comic's categories.
  final List<int> categories;
}
