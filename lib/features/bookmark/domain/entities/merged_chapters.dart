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

/// The chapters of several sources' lists, most wanted first, newest
/// first by number; chapters without a numeric number keep their place
/// after the numbered ones.
///
/// With [dedupe], one chapter per number: the first list that has it gives
/// it. Without, every chapter, those of one number in the lists' order.
List<Chapter> mergeChapters(
  List<List<Chapter>> bySource, {
  bool dedupe = true,
}) {
  final numbers = <String>{};
  // (number, place): the place keeps the lists' order among equal numbers.
  final numbered = <(double, int, Chapter)>[];
  final other = <Chapter>[];
  for (final chapters in bySource) {
    for (final c in chapters) {
      if (dedupe && !numbers.add(c.number)) continue;
      if (double.tryParse(c.number) case final n?) {
        numbered.add((n, numbered.length, c));
      } else {
        other.add(c);
      }
    }
  }
  numbered.sort((a, b) {
    final byNumber = b.$1.compareTo(a.$1);
    return byNumber != 0 ? byNumber : a.$2.compareTo(b.$2);
  });
  return [for (final (_, _, c) in numbered) c, ...other];
}

/// The chapters before and after [index] in a merged list, newest first,
/// skipping the other sources' copies of its number: of a number several
/// sources have, the first (most wanted) one.
({Chapter? previous, Chapter? next}) neighboursIn(
  List<Chapter> chapters,
  int index,
) {
  final number = chapters[index].number;
  Chapter? next;
  for (var j = index - 1; j >= 0; j--) {
    if (chapters[j].number == number) continue;
    var first = j;
    while (first > 0 && chapters[first - 1].number == chapters[j].number) {
      first--;
    }
    next = chapters[first];
    break;
  }
  Chapter? previous;
  for (var j = index + 1; j < chapters.length; j++) {
    if (chapters[j].number != number) {
      previous = chapters[j];
      break;
    }
  }
  return (previous: previous, next: next);
}
