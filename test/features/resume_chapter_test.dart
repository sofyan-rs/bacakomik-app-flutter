import 'package:bacakomik_app/core/domain/entities/comic_details.dart';
import 'package:bacakomik_app/features/history/domain/entities/read_history.dart';
import 'package:bacakomik_app/features/history/domain/entities/resume_chapter.dart';
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

ReadHistory _read(String number, {int? page}) => ReadHistory(
  slug: 'comic/$number',
  chapterNumber: number,
  readDate: DateTime(2026),
  comicDetails: _details(const []),
  comicSlug: 'comic',
  page: page,
  pageCount: page == null ? null : 20,
);

List<Chapter> _chapters(List<String> numbers) => _details(numbers).chapters;

void main() {
  test('an unfinished latest chapter reopens', () {
    final r = ResumeChapter.of(_read('5', page: 3), _chapters(['6', '5']));
    expect(r.slug, 'comic/5');
    expect(r.isNext, isFalse);
  });

  test('a finished latest chapter moves on to the next', () {
    final r = ResumeChapter.of(_read('5'), _chapters(['7', '6', '5', '4']));
    expect(r.slug, 'comic/6');
    expect(r.number, '6');
    expect(r.isNext, isTrue);
  });

  test('ranks by number whatever the list order', () {
    final r = ResumeChapter.of(_read('5'), _chapters(['4', '5', '7', '6']));
    expect(r.number, '6');
  });

  test('a finished newest chapter reopens', () {
    final r = ResumeChapter.of(_read('5'), _chapters(['5', '4']));
    expect(r.slug, 'comic/5');
    expect(r.isNext, isFalse);
  });

  test('fractional chapters come in between', () {
    final chapters = _chapters(['11', '10.5', '10']);
    expect(ResumeChapter.of(_read('10'), chapters).number, '10.5');
    expect(ResumeChapter.of(_read('10.5'), chapters).number, '11');
  });

  test('without a chapter list the latest chapter reopens', () {
    final r = ResumeChapter.of(_read('5'), const []);
    expect(r.slug, 'comic/5');
    expect(r.isNext, isFalse);
  });

  test('an unparsable number moves on by list order', () {
    final r = ResumeChapter.of(_read('extra'), _chapters(['2', 'extra', '1']));
    expect(r.number, '2');
    expect(r.isNext, isTrue);
  });
}
