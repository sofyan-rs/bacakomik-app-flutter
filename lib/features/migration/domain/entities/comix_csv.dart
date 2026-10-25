/// One row of a Comix.to library export (`manga-list-<date>.csv`).
class ComixCsvEntry {
  const ComixCsvEntry({required this.title, this.lastRead});

  final String title;

  /// Last chapter read, e.g. `7` or `42.2`; null when none was.
  final String? lastRead;
}

/// Reads a Comix.to export: a header row
/// `title,chapter,folder,url_mal,url_al,url_mu`, then one comic per row.
/// The export has no Comix link, so comics are found again by title.
/// Throws [FormatException] when there is no `title` column.
List<ComixCsvEntry> parseComixCsv(String text) {
  final rows = _rows(text);
  if (rows.isEmpty) throw const FormatException('Empty file');
  final header = [for (final h in rows.first) h.trim().toLowerCase()];
  final title = header.indexOf('title');
  final chapter = header.indexOf('chapter');
  if (title < 0) throw const FormatException('No title column');
  return [
    for (final row in rows.skip(1))
      if (row.length > title && row[title].trim().isNotEmpty)
        ComixCsvEntry(
          title: row[title].trim(),
          lastRead: chapter >= 0 && row.length > chapter
              ? _chapter(row[chapter])
              : null,
        ),
  ];
}

/// `7.000` → `7`, `42.200` → `42.2`, `0.000` → null.
String? _chapter(String raw) {
  final n = num.tryParse(raw.trim());
  if (n == null || n <= 0) return null;
  if (n == n.truncate()) return '${n.toInt()}';
  return '$n';
}

/// RFC 4180 rows: quoted fields may hold commas, line breaks and `""`.
List<List<String>> _rows(String text) {
  final rows = <List<String>>[];
  var row = <String>[];
  final field = StringBuffer();
  var quoted = false;

  void endField() {
    row.add(field.toString());
    field.clear();
  }

  void endRow() {
    endField();
    if (row.length > 1 || row.first.isNotEmpty) rows.add(row);
    row = <String>[];
  }

  for (var i = text.startsWith('﻿') ? 1 : 0; i < text.length; i++) {
    final ch = text[i];
    if (quoted) {
      if (ch != '"') {
        field.write(ch);
      } else if (i + 1 < text.length && text[i + 1] == '"') {
        field.write('"');
        i++;
      } else {
        quoted = false;
      }
    } else if (ch == '"') {
      quoted = true;
    } else if (ch == ',') {
      endField();
    } else if (ch == '\n') {
      endRow();
    } else if (ch != '\r') {
      field.write(ch);
    }
  }
  if (field.isNotEmpty || row.isNotEmpty) endRow();
  return rows;
}
