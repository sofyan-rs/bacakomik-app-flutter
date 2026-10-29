import 'package:bacakomik_app/core/domain/entities/comic_details.dart';

/// The series key of a chapter slug (`seriesKey/number`): the comic, and
/// so the source, the chapter is read from.
String seriesKeyOfChapter(String chapterSlug) {
  final i = chapterSlug.lastIndexOf('/');
  return i > 0 ? chapterSlug.substring(0, i) : chapterSlug;
}

/// Whether [chapters] come from more than one series: the list of a merged
/// bookmark.
bool isMergedList(List<Chapter> chapters) {
  if (chapters.isEmpty) return false;
  final first = seriesKeyOfChapter(chapters.first.slug);
  return chapters.any((c) => seriesKeyOfChapter(c.slug) != first);
}

/// The chapters of [chapters] read from [seriesKey].
List<Chapter> chaptersOf(List<Chapter> chapters, String seriesKey) => [
  for (final c in chapters)
    if (seriesKeyOfChapter(c.slug) == seriesKey) c,
];

/// One chapter per number from the lists of several sources, most wanted
/// first: each number comes from the first list that has it. Newest first,
/// by number; chapters without a numeric number keep their place after the
/// numbered ones.
List<Chapter> mergeChapters(List<List<Chapter>> bySource) {
  final byNumber = <String, Chapter>{};
  for (final chapters in bySource) {
    for (final c in chapters) {
      byNumber.putIfAbsent(c.number, () => c);
    }
  }
  final numbered = <(double, Chapter)>[];
  final other = <Chapter>[];
  for (final c in byNumber.values) {
    if (double.tryParse(c.number) case final n?) {
      numbered.add((n, c));
    } else {
      other.add(c);
    }
  }
  numbered.sort((a, b) => b.$1.compareTo(a.$1));
  return [for (final (_, c) in numbered) c, ...other];
}
