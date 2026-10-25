/// Separators sites put between alternative titles; ` / ` but not `1/2`.
/// A line break is how a source's list is stored in
/// `ComicDetails.alternativeTitle`.
final _strongSeparator = RegExp(r'\s*[•|;\n]\s*|\s+/\s+');

/// Titles have commas too, so `, ` splits only when nothing else does.
/// A comma without a space stays (`10,000 Years`).
final _commaSeparator = RegExp(r'\s*,\s+');

/// Separators left at either end of a part (`Title ,`).
final _edges = RegExp(r'^[\s,;•|]+|[\s,;•|]+$');

final _spaces = RegExp(r'\s+');

/// Values sources send for "no alternative title". `Field Kosong` is
/// VoraToon's.
const _placeholders = {
  '',
  '-',
  '?',
  'n/a',
  'none',
  'unknown',
  'updating',
  'tba',
  'tbd',
  'field kosong',
};

/// The alternative titles in [raw], in the source's order, without
/// placeholders, repeats or [title].
///
/// Newer extensions send a list (stored one per line). Older ones and stored
/// details have one string: a native title, or a list that mixes English,
/// romaji and native titles and may repeat the main title.
List<String> splitAltTitles(String title, String raw) {
  String key(String s) => s
      .replaceAll(_spaces, ' ')
      .trim()
      .toLowerCase()
      .replaceAll(RegExp('[‘’`]'), "'");
  final separator = _strongSeparator.hasMatch(raw)
      ? _strongSeparator
      : _commaSeparator;
  final seen = {key(title)};
  return [
    for (final part in raw.split(separator))
      if (part.replaceAll(_spaces, ' ').replaceAll(_edges, '') case final p
          when !_placeholders.contains(p.toLowerCase()) && seen.add(key(p)))
        p,
  ];
}
