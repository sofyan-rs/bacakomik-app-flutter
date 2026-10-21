import 'package:bacakomik_app/core/domain/entities/comic_details.dart';
import 'package:bacakomik_app/features/bookmark/domain/entities/bookmark.dart';
import 'package:bacakomik_app/features/bookmark/presentation/widgets/bookmark_progress.dart';
import 'package:bacakomik_app/features/history/domain/entities/read_history.dart';
import 'package:flutter_test/flutter_test.dart';

ComicDetails _details(String slug, int chapters) => ComicDetails(
  title: 'Comic',
  coverImg: '',
  alternativeTitle: '-',
  released: '-',
  status: 'Ongoing',
  totalChapter: '$chapters',
  author: '-',
  type: 'Manhwa',
  rating: '8',
  synopsis: '',
  genres: const [],
  chapters: [
    for (var n = chapters; n >= 1; n--)
      Chapter(number: '$n', slug: '$slug/$n', date: '-'),
  ],
);

Bookmark _bookmark(String slug, int chapters) => Bookmark(
  slug: slug,
  comicDetails: _details(slug, chapters),
  updatedDate: DateTime(2026),
);

ReadHistory _read(String slug, int chapter, {int day = 1}) => ReadHistory(
  slug: '$slug/$chapter',
  chapterNumber: '$chapter',
  readDate: DateTime(2026, 1, day),
  comicDetails: _details(slug, chapter),
  comicSlug: slug,
);

void main() {
  final items = BookmarkProgress.of(
    [
      _bookmark('behind', 10),
      _bookmark('done', 5),
      _bookmark('new', 7),
      _bookmark('reread', 5),
    ],
    HistoryIndex([
      _read('behind', 6),
      _read('behind', 7),
      for (var n = 1; n <= 5; n++) _read('done', n),
      for (var n = 5; n >= 1; n--) _read('reread', n, day: 6 - n),
    ]).containsChapter,
  );
  final behind = items[0];
  final done = items[1];
  final unopened = items[2];
  final reread = items[3];

  test('new chapters count the chapters not read yet', () {
    expect(behind.read, 2);
    expect(behind.newChapters, 8);
    expect(behind.hasUpdate, isTrue);
    expect(behind.isFinished, isFalse);
  });

  test('reading every chapter finishes the comic', () {
    expect(done.newChapters, 0);
    expect(done.isFinished, isTrue);
  });

  test('reading an early chapter last does not bring the badge back', () {
    expect(reread.read, 5);
    expect(reread.newChapters, 0);
    expect(reread.isFinished, isTrue);
  });

  test('comics never opened count every chapter as new', () {
    expect(unopened.read, 0);
    expect(unopened.newChapters, unopened.total);
    expect(unopened.hasUpdate, isTrue);
    expect(unopened.isFinished, isFalse);
  });

  test('filters', () {
    List<String> slugs(BookmarkFilter f) => [
      for (final i in items.where((i) => i.matches(f))) i.bookmark.slug,
    ];

    expect(slugs(BookmarkFilter.all), ['behind', 'done', 'new', 'reread']);
    expect(slugs(BookmarkFilter.updated), ['behind', 'new']);
    expect(slugs(BookmarkFilter.finished), ['done', 'reread']);
  });
}
