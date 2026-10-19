import 'package:bacakomik_app/core/domain/entities/comic_details.dart';
import 'package:bacakomik_app/features/history/domain/entities/read_history.dart';
import 'package:flutter_test/flutter_test.dart';

const _details = ComicDetails(
  title: 'Comic',
  coverImg: '',
  alternativeTitle: '-',
  released: '-',
  status: 'Ongoing',
  totalChapter: '0',
  author: '-',
  type: 'Manga',
  rating: '8',
  synopsis: '',
  genres: [],
  chapters: [],
);

ReadHistory _read(String comic, int chapter, int day) => ReadHistory(
  slug: '$comic/$chapter',
  chapterNumber: '$chapter',
  readDate: DateTime(2026, 10, day),
  comicDetails: _details,
  comicSlug: comic,
);

void main() {
  final history = [
    _read('a', 1, 1),
    _read('b', 1, 3),
    _read('a', 2, 4),
    _read('b', 2, 2),
  ];

  test('index answers like the list queries, in any order', () {
    for (final list in [history, history.reversed.toList()]) {
      final index = HistoryIndex(list);

      expect(index.latest?.slug, list.latest?.slug);
      expect(index.latest?.slug, 'a/2');
      expect(index.latestOf('b')?.slug, 'b/1');
      expect(index.latestOf('b')?.slug, list.latestOf('b')?.slug);
      expect(index.latestOf('missing'), isNull);
      expect(index.countOf('a'), 2);
      expect(index.containsChapter('b/2'), isTrue);
      expect(index.containsChapter('c/1'), isFalse);
      expect([for (final c in index.perComic) c.comicSlug], ['a', 'b']);
    }
  });

  test('empty history', () {
    final index = HistoryIndex(const []);
    expect(index.latest, isNull);
    expect(index.perComic, isEmpty);
  });
}
