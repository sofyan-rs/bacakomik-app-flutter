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

  /// The newest of [dates] read with [parse], or null when none reads.
  /// Gives what calling [parse] on each and keeping the latest (the first
  /// of equal ones) gives, without a regex or a [DateTime] per chapter:
  /// relative dates compare by their age, absolute ones by their day number,
  /// and only the two winners become dates.
  static DateTime? latest(Iterable<String> dates, {required DateTime madeAt}) {
    // Youngest relative date: its age and position.
    Duration? age;
    var ageAt = -1;
    // Newest absolute date: its day number, fields and position.
    var day = 0;
    var dayAt = -1;
    var (year, month, dayOfMonth) = (0, 0, 0);
    var i = -1;
    for (final date in dates) {
      i++;
      if (_ageOf(date) case final a?) {
        if (age == null || a < age) (age, ageAt) = (a, i);
        continue;
      }
      if (_absoluteOf(date) case (final y, final m, final d)) {
        final n = _daysFromCivil(y, m, 1) + d - 1;
        if (dayAt < 0 || n > day) {
          (day, dayAt) = (n, i);
          (year, month, dayOfMonth) = (y, m, d);
        }
      }
    }
    final relative = age == null ? null : madeAt.subtract(age);
    final absolute = dayAt < 0 ? null : DateTime(year, month, dayOfMonth);
    if (relative == null) return absolute;
    if (absolute == null) return relative;
    if (absolute.isAfter(relative)) return absolute;
    if (relative.isAfter(absolute)) return relative;
    return ageAt < dayAt ? relative : absolute;
  }

  /// How long before the list was made a relative date is ([parse]).
  static Duration? _ageOf(String date) {
    if (date == 'Just now') return Duration.zero;
    if (!date.endsWith(' ago')) return null;
    var end = 0;
    while (end < date.length && _isDigit(date.codeUnitAt(end))) {
      end++;
    }
    if (end == 0 || end + 1 > date.length - 4 || date.codeUnitAt(end) != 0x20) {
      return null;
    }
    final unit = date.substring(end + 1, date.length - 4);
    final make = switch (unit) {
      'min' => (int n) => Duration(minutes: n),
      'h' => (int n) => Duration(hours: n),
      'day' || 'days' => (int n) => Duration(days: n),
      _ => null,
    };
    return make?.call(int.parse(date.substring(0, end)));
  }

  /// Day, month and year of `dd/mm/yyyy` with a valid day and month.
  static (int, int, int)? _absoluteOf(String date) {
    if (date.length != 10 ||
        date.codeUnitAt(2) != 0x2F ||
        date.codeUnitAt(5) != 0x2F) {
      return null;
    }
    int? number(int from, int to) {
      var n = 0;
      for (var k = from; k < to; k++) {
        final c = date.codeUnitAt(k);
        if (!_isDigit(c)) return null;
        n = n * 10 + c - 0x30;
      }
      return n;
    }

    final (day, month, year) = (number(0, 2), number(3, 5), number(6, 10));
    if (day == null || month == null || year == null) return null;
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;
    return (year, month, day);
  }

  static bool _isDigit(int c) => c >= 0x30 && c <= 0x39;

  /// Days from 1970-01-01 to a proleptic Gregorian date.
  static int _daysFromCivil(int year, int month, int day) {
    final y = month <= 2 ? year - 1 : year;
    final era = (y >= 0 ? y : y - 399) ~/ 400;
    final yearOfEra = y - era * 400;
    final dayOfYear = (153 * (month + (month > 2 ? -3 : 9)) + 2) ~/ 5 + day - 1;
    final dayOfEra =
        yearOfEra * 365 + yearOfEra ~/ 4 - yearOfEra ~/ 100 + dayOfYear;
    return era * 146097 + dayOfEra - 719468;
  }
}
