/// Identifies a comic across sources. The app stores and passes this key
/// wherever it used to pass a series slug (library, history, downloads, deep
/// links), so the same title from two sources stays two separate entries.
///
/// Comics of [defaultSource] keep their bare slug, which is what every key
/// stored before sources existed looks like. Other sources prefix the slug:
/// `voratoon:god-martial-arts`.
abstract final class ComicKey {
  /// Source of keys without a prefix.
  static const defaultSource = 'bacakomik';

  static const _separator = ':';

  static String of(String sourceId, String slug) =>
      sourceId == defaultSource ? slug : '$sourceId$_separator$slug';

  static String sourceOf(String key) {
    final i = key.indexOf(_separator);
    return i > 0 ? key.substring(0, i) : defaultSource;
  }

  static String slugOf(String key) {
    final i = key.indexOf(_separator);
    return i > 0 ? key.substring(i + 1) : key;
  }
}
