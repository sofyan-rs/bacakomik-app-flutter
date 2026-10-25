import 'package:bacakomik_app/features/comic_detail/presentation/widgets/chapter_date.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('chapters from the last 24 hours are new', () {
    expect(ChapterDate.isNew('Just now'), isTrue);
    expect(ChapterDate.isNew('12 min ago'), isTrue);
    expect(ChapterDate.isNew('23 h ago'), isTrue);
    expect(ChapterDate.isNew('1 day ago'), isFalse);
    expect(ChapterDate.isNew('01/02/2025'), isFalse);
    expect(ChapterDate.isNew('-'), isFalse);
  });

  test('short dates', () {
    expect(ChapterDate.short('12 min ago'), '12 min');
    expect(ChapterDate.short('3 h ago'), '3 h');
    expect(ChapterDate.short('7 days ago'), '7 d');
    expect(ChapterDate.short('1 day ago'), '1 d');
    expect(ChapterDate.short('01/02/2025'), '01/02/2025');
  });

  test('latest gives what parsing every date gives', () {
    DateTime? byParse(List<String> dates, DateTime madeAt) {
      DateTime? latest;
      for (final d in dates) {
        final date = ChapterDate.parse(d, madeAt: madeAt);
        if (date != null && (latest == null || date.isAfter(latest))) {
          latest = date;
        }
      }
      return latest;
    }

    final madeAt = DateTime(2025, 3, 10, 15, 30);
    final cases = [
      <String>[],
      ['-', ''],
      ['Just now', '3 h ago'],
      ['3 h ago', '12 min ago', '1 day ago', '7 days ago'],
      ['01/02/2025', '28/02/2025', '15/01/2025'],
      // Day 31 of February rolls over into March, as DateTime does.
      ['31/02/2025', '01/03/2025'],
      ['09/03/2025', '2 days ago'],
      ['10/03/2025', '16 h ago', '15 h ago'],
      [
        '01/13/2025',
        '00/01/2025',
        '1/1/2025',
        '3 ago',
        ' h ago',
        '3 hours ago',
      ],
      ['3 h ago', '180 min ago'],
      ['10/03/2025', '930 min ago'],
      ['930 min ago', '10/03/2025'],
      ['01/02/1969', '-'],
    ];
    for (final dates in cases) {
      for (final at in [madeAt, madeAt.toUtc()]) {
        expect(
          ChapterDate.latest(dates, madeAt: at),
          byParse(dates, at),
          reason: '$dates at $at',
        );
      }
    }
  });
}
