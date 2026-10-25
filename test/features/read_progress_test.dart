import 'package:bacakomik_app/core/domain/entities/comic_details.dart';
import 'package:bacakomik_app/features/history/domain/entities/read_progress.dart';
import 'package:flutter_test/flutter_test.dart';

ComicDetails _details(List<String> numbers) => ComicDetails(
  title: 'Comic',
  coverImg: '',
  alternativeTitle: '-',
  released: '-',
  status: 'Ongoing',
  totalChapter: '${numbers.length}',
  author: '-',
  type: 'Manhwa',
  rating: '7.5',
  synopsis: '',
  genres: const [],
  chapters: [
    for (final n in numbers) Chapter(number: n, slug: 'comic/$n', date: '-'),
  ],
);

void main() {
  test('ranks by chapter number whatever the list order', () {
    final newestFirst = ReadProgress.of(_details(['3', '2', '1']), '2');
    final oldestFirst = ReadProgress.of(_details(['1', '2', '3']), '2');

    for (final p in [newestFirst, oldestFirst]) {
      expect(p.position, 2);
      expect(p.total, 3);
      expect(p.latestNumber, '3');
      expect(p.unread, 1);
      expect(p.isFinished, isFalse);
    }
  });

  test('counts fractional chapters', () {
    final p = ReadProgress.of(_details(['533', '533.5', '534']), '533.5');
    expect(p.position, 2);
    expect(p.latestNumber, '534');
  });

  test('reading the last chapter finishes the comic', () {
    final p = ReadProgress.of(_details(['1', '2']), '2');
    expect(p.isFinished, isTrue);
    expect(p.unread, 0);
  });

  test('chapters without a number are left out of the total', () {
    final p = ReadProgress.of(_details(['2', 'extra', '1']), '2');
    expect(p.total, 2);
    expect(p.isFinished, isTrue);
  });

  test('unparsable chapter number shows no progress', () {
    final p = ReadProgress.of(_details(['1', '2']), 'extra');
    expect(p.position, 0);
    expect(p.latestNumber, '2');
  });
}
