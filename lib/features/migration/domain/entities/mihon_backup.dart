/// What the app reads from a Mihon/Tachiyomi backup (`.tachibk`): each
/// comic's source, link, title, categories, chapters and reading history.
/// Covers and details are left out; the comic's source loads them later.
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
    this.chapters = const [],
    this.history = const {},
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

  /// Chapters as stored in Mihon, in the backup's order.
  final List<MihonChapter> chapters;

  /// When each chapter was last read, by [MihonChapter.url]. Mihon keeps
  /// it only for chapters opened in the reader, not ones marked read.
  final Map<String, DateTime> history;

  /// Highest chapter number marked read, e.g. `14` or `10.5`; null when
  /// none is.
  String? get lastRead {
    MihonChapter? last;
    for (final c in chapters) {
      if (c.read && c.numbered && (last == null || c.number > last.number)) {
        last = c;
      }
    }
    return last?.numberText;
  }
}

class MihonChapter {
  const MihonChapter({
    required this.url,
    required this.number,
    this.read = false,
    this.fetched,
    this.uploaded,
  });

  /// Chapter link relative to the source's site; [MihonManga.history] is
  /// keyed by it.
  final String url;

  /// Chapter number; negative when the source gave none.
  final double number;
  final bool read;

  /// When Mihon added the chapter to its list.
  final DateTime? fetched;

  /// When the source released the chapter.
  final DateTime? uploaded;

  bool get numbered => number >= 0;

  /// [number] as the app writes chapter numbers: `14.0` → `14`, a float's
  /// noise trimmed: `42.2000007` → `42.2`.
  String get numberText {
    final text = number.toStringAsFixed(3).replaceFirst(RegExp(r'\.?0+$'), '');
    return text.isEmpty ? '0' : text;
  }
}
