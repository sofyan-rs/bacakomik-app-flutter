import 'package:bacakomik_app/core/domain/entities/comic_details.dart';
import 'package:bacakomik_app/features/history/domain/entities/read_history.dart';
import 'package:bacakomik_app/features/history/presentation/widgets/history_groups.dart';
import 'package:flutter_test/flutter_test.dart';

const _details = ComicDetails(
  title: 'Comic',
  coverImg: '',
  alternativeTitle: '-',
  released: '-',
  status: 'Ongoing',
  totalChapter: '1',
  author: '-',
  type: 'Manga',
  rating: '8',
  synopsis: '',
  genres: [],
  chapters: [],
);

ComicLatestHistory _item(String slug, DateTime readDate) => ComicLatestHistory(
  comicSlug: slug,
  comicDetails: _details,
  latestHistory: ReadHistory(
    slug: '$slug/1',
    chapterNumber: '1',
    readDate: readDate,
    comicDetails: _details,
    comicSlug: slug,
  ),
);

void main() {
  final now = DateTime(2026, 10, 19, 13);

  test('groups by day with relative labels, keeping order', () {
    final days = HistoryDay.group([
      _item('a', DateTime(2026, 10, 19, 10, 33)),
      _item('b', DateTime(2026, 10, 19, 9, 12)),
      _item('c', DateTime(2026, 10, 18, 22, 47)),
      _item('d', DateTime(2026, 10, 1, 8)),
    ], now);

    expect(
      [for (final d in days) d.label],
      ['Hari ini', 'Kemarin', '1 Okt 2026'],
    );
    expect([for (final i in days.first.items) i.comicSlug], ['a', 'b']);
  });

  test('time is zero padded', () {
    expect(HistoryDay.time(DateTime(2026, 1, 1, 9, 5)), '09:05');
  });
}
