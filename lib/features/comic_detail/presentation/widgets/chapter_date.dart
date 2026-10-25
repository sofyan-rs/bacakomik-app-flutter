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

  static final _relative = RegExp(r'^(\d+) (min|h|day|days) ago$');
  static final _absolute = RegExp(r'^(\d{2})/(\d{2})/(\d{4})$');

  /// The release time [date] stands for. Relative dates count back from
  /// [madeAt], when the text was made (the chapter list was fetched).
  /// Null for text in no known form, like `-`.
  static DateTime? parse(String date, {required DateTime madeAt}) {
    if (date == 'Just now') return madeAt;
    if (_relative.firstMatch(date) case final m?) {
      final n = int.parse(m[1]!);
      return madeAt.subtract(switch (m[2]) {
        'min' => Duration(minutes: n),
        'h' => Duration(hours: n),
        _ => Duration(days: n),
      });
    }
    if (_absolute.firstMatch(date) case final m?) {
      final (day, month) = (int.parse(m[1]!), int.parse(m[2]!));
      if (month < 1 || month > 12 || day < 1 || day > 31) return null;
      return DateTime(int.parse(m[3]!), month, day);
    }
    return null;
  }
}
