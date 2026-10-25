import 'package:bacakomik_app/core/domain/entities/comic_details.dart';
import 'package:bacakomik_app/features/history/domain/entities/read_history.dart';

/// The chapter "continue reading" opens for a comic with history.
///
/// An unfinished latest chapter reopens at its saved page. A finished one
/// moves on to the next chapter by number (`10` → `10.5` → `11`), since the
/// API does not promise a list order. With no next chapter yet, the latest
/// one reopens.
class ResumeChapter {
  const ResumeChapter({
    required this.slug,
    required this.number,
    required this.isNext,
  });

  final String slug;

  /// Chapter number as displayed (`10.5`).
  final String number;

  /// Whether this is the chapter after the finished latest one, rather
  /// than the latest one itself.
  final bool isNext;

  /// [chapters] should be the freshest list available, so chapters released
  /// since [latest] was read are found.
  static ResumeChapter of(ReadHistory latest, List<Chapter> chapters) {
    final current = ResumeChapter(
      slug: latest.slug,
      number: latest.chapterNumber,
      isNext: false,
    );
    if (!latest.isFinished) return current;

    final next =
        _nextByNumber(latest, chapters) ?? _nextByOrder(latest, chapters);
    if (next == null) return current;
    return ResumeChapter(slug: next.slug, number: next.number, isNext: true);
  }

  /// Lowest numbered chapter above [latest]'s number.
  static Chapter? _nextByNumber(ReadHistory latest, List<Chapter> chapters) {
    final read = double.tryParse(latest.chapterNumber);
    if (read == null) return null;
    Chapter? next;
    double? nextValue;
    for (final chapter in chapters) {
      final value = double.tryParse(chapter.number);
      if (value == null || value <= read) continue;
      if (nextValue == null || value < nextValue) {
        next = chapter;
        nextValue = value;
      }
    }
    return next;
  }

  /// The chapter listed before [latest] (the list is newest first), for
  /// numbers that do not parse.
  static Chapter? _nextByOrder(ReadHistory latest, List<Chapter> chapters) {
    if (double.tryParse(latest.chapterNumber) != null) return null;
    final i = chapters.indexWhere((c) => c.slug == latest.slug);
    return i > 0 ? chapters[i - 1] : null;
  }
}

/// [chapters] newest first: by number, highest first (`11`, `10.5`, `10`),
/// when every number parses; otherwise as given, since sources usually list
/// newest first. Equal numbers keep their order.
List<Chapter> chaptersNewestFirst(List<Chapter> chapters) {
  final values = [for (final c in chapters) double.tryParse(c.number)];
  if (values.contains(null)) return chapters;
  final order = List.generate(chapters.length, (i) => i)
    ..sort((a, b) {
      final byNumber = values[b]!.compareTo(values[a]!);
      return byNumber != 0 ? byNumber : a.compareTo(b);
    });
  return [for (final i in order) chapters[i]];
}

/// The chapter to start reading with: the lowest numbered one, or the last
/// listed when a number does not parse. Null without chapters.
Chapter? firstChapter(List<Chapter> chapters) {
  Chapter? first;
  double? firstValue;
  for (final chapter in chapters) {
    final value = double.tryParse(chapter.number);
    if (value == null) return chapters.lastOrNull;
    if (firstValue == null || value < firstValue) {
      first = chapter;
      firstValue = value;
    }
  }
  return first;
}
