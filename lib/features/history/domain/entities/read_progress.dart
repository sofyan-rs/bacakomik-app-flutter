import 'package:bacakomik_app/core/domain/entities/comic_details.dart';

/// How far a comic has been read, from the last read chapter: shown as
/// `CH. 67 / 88` with a dot meter.
///
/// Chapters are ranked by number, not list order, because the API does not
/// promise an order and some numbers are fractional (`533.5`).
class ReadProgress {
  const ReadProgress({
    required this.chapterNumber,
    required this.latestNumber,
    required this.position,
    required this.total,
  });

  /// Last read chapter, as displayed (`67`).
  final String chapterNumber;

  /// Highest chapter number of the comic (`88`).
  final String latestNumber;

  /// 1-based rank of the read chapter among all chapters by number.
  final int position;
  final int total;

  /// Chapters released after the read one.
  int get unread => total - position;

  bool get isFinished => total > 0 && position >= total;

  static ReadProgress of(ComicDetails details, String chapterNumber) {
    final read = double.tryParse(chapterNumber);
    final numbers = [
      for (final chapter in details.chapters)
        (chapter.number, double.tryParse(chapter.number)),
    ];

    var latest = chapterNumber;
    var latestValue = read ?? double.negativeInfinity;
    var position = 0;
    for (final (label, value) in numbers) {
      if (value == null) continue;
      if (value > latestValue) {
        latestValue = value;
        latest = label;
      }
      if (read != null && value <= read) position++;
    }

    return ReadProgress(
      chapterNumber: chapterNumber,
      latestNumber: latest,
      position: position,
      total: details.chapters.length,
    );
  }
}
