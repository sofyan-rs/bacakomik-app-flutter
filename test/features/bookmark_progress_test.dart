import 'package:bacakomik_app/core/domain/entities/comic_details.dart';
import 'package:bacakomik_app/features/bookmark/domain/entities/bookmark.dart';
import 'package:bacakomik_app/features/bookmark/presentation/widgets/bookmark_progress.dart';
import 'package:bacakomik_app/features/history/domain/entities/read_history.dart';
import 'package:flutter_test/flutter_test.dart';

ComicDetails _details(int chapters) => ComicDetails(
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
      Chapter(number: '$n', slug: 'x/$n', date: '-'),
  ],
);

Bookmark _bookmark(String slug, int chapters) => Bookmark(
  slug: slug,
  comicDetails: _details(chapters),
  updatedDate: DateTime(2026),
);

ReadHistory _read(String slug, int chapter) => ReadHistory(
  slug: '$slug/$chapter',
  chapterNumber: '$chapter',
  readDate: DateTime(2026, 1, chapter),
  comicDetails: _details(chapter),
  comicSlug: slug,
);

void main() {
  final items = BookmarkProgress.of(
    [_bookmark('behind', 10), _bookmark('done', 5), _bookmark('new', 7)],
    HistoryIndex([_read('behind', 6), _read('behind', 7), _read('done', 5)])
        .latestOf,
  );
  final behind = items[0];
  final done = items[1];
  final unopened = items[2];

  test('new chapters count from the latest read chapter', () {
    expect(behind.newChapters, 3);
    expect(behind.hasUpdate, isTrue);
    expect(behind.isFinished, isFalse);
  });

  test('reading every chapter finishes the comic', () {
    expect(done.newChapters, 0);
    expect(done.isFinished, isTrue);
  });

  test('comics never opened have no badge and are not finished', () {
    expect(unopened.progress, isNull);
    expect(unopened.newChapters, 0);
    expect(unopened.isFinished, isFalse);
  });

  test('filters', () {
    List<String> slugs(BookmarkFilter f) => [
      for (final i in items.where((i) => i.matches(f))) i.bookmark.slug,
    ];

    expect(slugs(BookmarkFilter.all), ['behind', 'done', 'new']);
    expect(slugs(BookmarkFilter.updated), ['behind']);
    expect(slugs(BookmarkFilter.finished), ['done']);
  });
}
