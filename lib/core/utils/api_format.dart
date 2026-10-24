/// Helpers to convert bacakomik-api values into the strings shown by the UI.
class ApiFormat {
  static String number(num? value) {
    if (value == null) return '-';
    return value == value.truncate() ? value.toInt().toString() : '$value';
  }

  static String capitalize(String? value, {String fallback = '-'}) {
    if (value == null || value.isEmpty) return fallback;
    return value[0].toUpperCase() + value.substring(1);
  }

  static String rating(num? value) {
    if (value == null) return '-';
    return value.toStringAsFixed(value == value.truncate() ? 0 : 1);
  }

  static String relativeDate(String? iso) {
    final date = iso != null ? DateTime.tryParse(iso)?.toLocal() : null;
    if (date == null) return '-';
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} h ago';
    if (diff.inDays == 1) return '1 day ago';
    if (diff.inDays < 30) return '${diff.inDays} days ago';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(date.day)}/${two(date.month)}/${date.year}';
  }

  /// Chapter slug used across the app (history, reader): `seriesSlug/number`.
  static String chapterSlug(String seriesSlug, num number) =>
      '$seriesSlug/${ApiFormat.number(number)}';
}
