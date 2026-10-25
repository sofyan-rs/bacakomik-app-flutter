import 'package:bacakomik_app/core/domain/entities/comic_details.dart';
import 'package:bacakomik_app/features/bookmark/data/models/bookmark_model.dart';
import 'package:bacakomik_app/features/bookmark/domain/entities/bookmark.dart';
import 'package:bacakomik_app/features/bookmark/presentation/widgets/bookmark_progress.dart';
import 'package:bacakomik_app/features/bookmark/presentation/widgets/bookmark_sort.dart';
import 'package:bacakomik_app/features/comic_detail/presentation/widgets/chapter_date.dart';
import 'package:bacakomik_app/features/settings/domain/entities/app_settings.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fixtures/library_fixtures.dart';

DateTime at(int ms) => DateTime.fromMillisecondsSinceEpoch(ms);

const _hour = 3600 * 1000;

BookmarkProgress item(
  String slug, {
  String title = 'Comic',
  int updated = 0,
  int? added,
  int chapters = 0,
  List<String>? dates,
  int? lastRead,
}) {
  final chapterDates = dates ?? List.filled(chapters, '-');
  return BookmarkProgress(
    Bookmark(
      slug: slug,
      comicDetails: sampleComicDetails.copyWith(
        title: title,
        chapters: [
          for (final (i, date) in chapterDates.indexed)
            Chapter(number: '${i + 1}', slug: '$slug/${i + 1}', date: date),
        ],
      ),
      updatedDate: at(updated),
      addedDate: added == null ? null : at(added),
    ),
    0,
    lastRead: lastRead == null ? null : at(lastRead),
  );
}

List<String> sorted(
  List<BookmarkProgress> items,
  BookmarkSort sort,
  SortDirection direction,
) => [for (final i in sortBookmarks(items, sort, direction)) i.bookmark.slug];

const asc = SortDirection.ascending;
const desc = SortDirection.descending;

void main() {
  group('sortBookmarks', () {
    test('the default is the repository order: newest update first', () {
      expect(const AppSettings().bookmarkSort, BookmarkSort.updated);
      expect(const AppSettings().bookmarkSortDirection, desc);
      // As BookmarkRepository returns them, with a tie on 200.
      final items = [
        item('c', title: 'C', updated: 300),
        item('b', title: 'B', updated: 200),
        item('a', title: 'A', updated: 200),
        item('d', title: 'D', updated: 100),
      ];

      expect(sorted(items, BookmarkSort.updated, desc), ['c', 'b', 'a', 'd']);
      expect(sorted(items, BookmarkSort.updated, asc), ['d', 'b', 'a', 'c']);
    });

    test('title ignores case', () {
      final items = [
        item('1', title: 'beta'),
        item('2', title: 'Alpha'),
        item('3', title: 'Gamma'),
      ];

      expect(sorted(items, BookmarkSort.title, asc), ['2', '1', '3']);
      expect(sorted(items, BookmarkSort.title, desc), ['3', '1', '2']);
    });

    test('total chapters, ties by title', () {
      final items = [
        item('few', title: 'Few', chapters: 2),
        item('many', title: 'Many', chapters: 9),
        item('b', title: 'B', chapters: 5),
        item('a', title: 'A', chapters: 5),
      ];

      expect(sorted(items, BookmarkSort.chapters, desc), [
        'many',
        'a',
        'b',
        'few',
      ]);
      expect(sorted(items, BookmarkSort.chapters, asc), [
        'few',
        'a',
        'b',
        'many',
      ]);
    });

    test('latest chapter reads relative and absolute dates', () {
      final items = [
        // Fetched at 10 h, newest chapter 2 h before: 8 h.
        item('rel', updated: 10 * _hour, dates: ['2 h ago', '1 day ago']),
        // Unreadable dates: the update time, 5 h.
        item('none', updated: 5 * _hour, dates: ['-', '-']),
        // No chapters yet (an imported placeholder): 1 h.
        item('empty', updated: 1 * _hour),
        // An old absolute date sorts before all of them.
        item('old', updated: 20 * _hour, dates: ['01/02/1969']),
      ];

      expect(sorted(items, BookmarkSort.latestChapter, desc), [
        'rel',
        'none',
        'empty',
        'old',
      ]);
      expect(sorted(items, BookmarkSort.latestChapter, asc), [
        'old',
        'empty',
        'none',
        'rel',
      ]);
    });

    test('date added falls back to the update date', () {
      final items = [
        item('new', added: 300, updated: 900),
        item('legacy', updated: 200),
        item('old', added: 100, updated: 800),
      ];

      expect(sorted(items, BookmarkSort.added, desc), ['new', 'legacy', 'old']);
      expect(sorted(items, BookmarkSort.added, asc), ['old', 'legacy', 'new']);
    });

    test('last read puts comics never read last both ways', () {
      final items = [
        item('never', title: 'A'),
        item('recent', lastRead: 900),
        item('long ago', lastRead: 100),
        item('never too', title: 'B'),
      ];

      expect(sorted(items, BookmarkSort.lastRead, desc), [
        'recent',
        'long ago',
        'never',
        'never too',
      ]);
      expect(sorted(items, BookmarkSort.lastRead, asc), [
        'long ago',
        'recent',
        'never',
        'never too',
      ]);
    });

    test('ties break by title, then key, in both directions', () {
      final items = [
        item('z', title: 'Same', added: 1),
        item('b', title: 'Bravo', added: 1),
        item('a', title: 'Same', added: 1),
      ];

      for (final direction in SortDirection.values) {
        expect(sorted(items, BookmarkSort.added, direction), ['b', 'a', 'z']);
      }
    });

    test('options start A to Z or newest first', () {
      expect(defaultDirectionOf(BookmarkSort.title), asc);
      for (final sort in BookmarkSort.values) {
        if (sort == BookmarkSort.title) continue;
        expect(defaultDirectionOf(sort), desc);
      }
    });
  });

  group('ChapterDate.parse', () {
    final madeAt = DateTime(2026, 5, 10, 12);

    test('relative dates count back from when they were made', () {
      DateTime? parse(String date) => ChapterDate.parse(date, madeAt: madeAt);

      expect(parse('Just now'), madeAt);
      expect(parse('12 min ago'), DateTime(2026, 5, 10, 11, 48));
      expect(parse('3 h ago'), DateTime(2026, 5, 10, 9));
      expect(parse('1 day ago'), DateTime(2026, 5, 9, 12));
      expect(parse('7 days ago'), DateTime(2026, 5, 3, 12));
    });

    test('absolute dates are day/month/year', () {
      expect(
        ChapterDate.parse('01/02/2025', madeAt: madeAt),
        DateTime(2025, 2, 1),
      );
    });

    test('anything else is unknown', () {
      for (final date in ['-', '', '2025-02-01', '40/13/2025', 'soon']) {
        expect(ChapterDate.parse(date, madeAt: madeAt), isNull, reason: date);
      }
    });
  });

  group('BookmarkModel', () {
    test('a bookmark stored without an added date still loads', () {
      final json = BookmarkModel.fromEntity(
        Bookmark(
          slug: 'a',
          comicDetails: sampleComicDetails,
          updatedDate: at(1700000000000),
        ),
      ).toJson();
      expect(json, isNot(contains('addedDate')));

      final bookmark = BookmarkModel.fromJson(json).toEntity();

      expect(bookmark.addedDate, isNull);
      expect(bookmark.updatedDate, at(1700000000000));
    });

    test('added date round-trips as epoch milliseconds', () {
      final bookmark = Bookmark(
        slug: 'a',
        comicDetails: sampleComicDetails,
        updatedDate: at(1700000000000),
        addedDate: at(1600000000000),
      );
      final json = BookmarkModel.fromEntity(bookmark).toJson();

      expect(json['addedDate'], 1600000000000);
      expect(BookmarkModel.fromJson(json).toEntity(), bookmark);
    });
  });
}
