/// Reads the relative dates made by `ApiFormat.relativeDate` ("Baru saja",
/// "12 menit lalu", "3 jam lalu", "7 hari lalu", "01/02/2025").
abstract final class ChapterDate {
  /// Released less than 24 hours ago (REDESIGN_PLAN D3).
  static bool isNew(String date) =>
      date == 'Baru saja' ||
      date.endsWith(' menit lalu') ||
      date.endsWith(' jam lalu');

  /// Compact form for chapter rows: `12 mnt`, `3 jam`, `7 hari`.
  static String short(String date) {
    if (date == 'Baru saja') return 'baru';
    for (final (long, short) in const [
      (' menit lalu', ' mnt'),
      (' jam lalu', ' jam'),
      (' hari lalu', ' hari'),
    ]) {
      if (date.endsWith(long)) {
        return date.substring(0, date.length - long.length) + short;
      }
    }
    return date;
  }
}
