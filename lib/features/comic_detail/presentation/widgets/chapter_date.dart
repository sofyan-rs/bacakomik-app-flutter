/// Reads the relative dates made by `ApiFormat.relativeDate` ("Just now",
/// "12 min ago", "3 h ago", "1 day ago", "7 days ago", "01/02/2025").
abstract final class ChapterDate {
  /// Released less than 24 hours ago.
  static bool isNew(String date) =>
      date == 'Just now' ||
      date.endsWith(' min ago') ||
      date.endsWith(' h ago');

  /// Compact form for chapter rows: `12 min`, `3 h`, `7 d`.
  static String short(String date) {
    if (date == 'Just now') return 'new';
    for (final (long, short) in const [
      (' min ago', ' min'),
      (' h ago', ' h'),
      (' days ago', ' d'),
      (' day ago', ' d'),
    ]) {
      if (date.endsWith(long)) {
        return date.substring(0, date.length - long.length) + short;
      }
    }
    return date;
  }
}
