import 'package:bacakomik_app/core/domain/entities/comic_details.dart';

import 'dart:math';

import 'package:bacakomik_app/features/history/domain/entities/read_history.dart';
import 'package:bacakomik_app/features/history/presentation/bloc/history_cubit.dart';
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

  test('incremental updates equal a rebuild from the edited list', () {
    final random = Random(7);
    const comics = ['a', 'b', 'c', 'd', 'e'];
    final variants = {
      for (final c in comics)
        c: [
          _details.copyWith(title: '$c one'),
          _details.copyWith(title: '$c two'),
        ],
    };
    var list = <ReadHistory>[];
    var index = HistoryIndex(list);

    void expectSame(String step) {
      final rebuilt = HistoryIndex(list);
      expect(index.perComic, rebuilt.perComic, reason: step);
      expect(index.latest, rebuilt.latest, reason: step);
      for (final c in [...comics, 'missing']) {
        expect(index.latestOf(c), rebuilt.latestOf(c), reason: '$step $c');
        expect(index.countOf(c), rebuilt.countOf(c), reason: '$step $c');
        expect(
          index.finishedCountOf(c),
          rebuilt.finishedCountOf(c),
          reason: '$step $c',
        );
      }
      for (final c in comics) {
        for (var n = 1; n <= 8; n++) {
          expect(index.chapter('$c/$n'), rebuilt.chapter('$c/$n'));
        }
      }
    }

    ReadHistory entry() {
      final comic = comics[random.nextInt(comics.length)];
      final n = 1 + random.nextInt(8);
      final unfinished = random.nextBool();
      return ReadHistory(
        slug: '$comic/$n',
        chapterNumber: '$n',
        // Few distinct times, so equal dates (ordered by slug) happen;
        // microseconds are dropped as the history stores them.
        readDate: DateTime(2026, 10, 1 + random.nextInt(4), 0, 0, 0, 0, 500),
        comicDetails: variants[comic]![random.nextInt(2)],
        comicSlug: comic,
        page: unfinished ? 3 : null,
        pageCount: unfinished ? 10 : null,
      );
    }

    for (var step = 0; step < 400; step++) {
      final op = random.nextInt(10);
      if (op < 6) {
        final saved = [for (var i = random.nextInt(3); i >= 0; i--) entry()];
        list = HistoryCubit.withSaved(list, saved);
        index.applySaved(saved);
      } else if (op < 8) {
        final slugs = {for (var i = 0; i < 2; i++) entry().slug};
        list = [
          for (final h in list)
            if (!slugs.contains(h.slug)) h,
        ];
        index.applyRemoved(slugs);
      } else if (op < 9 || list.length < 20) {
        final comic = comics[random.nextInt(comics.length)];
        list = [
          for (final h in list)
            if (h.comicSlug != comic) h,
        ];
        index.applyRemovedComics([comic]);
      } else {
        list = [];
        index.applyCleared();
      }
      expectSame('step $step');
    }
  });

  test('applySaved changes perComic only for the comics saved', () {
    final index = HistoryIndex(history.newestFirst);
    final before = index.perComic;
    final b = before.firstWhere((c) => c.comicSlug == 'b');

    index.applySaved([_read('a', 3, 9)]);

    expect(identical(index.perComic, before), isFalse);
    expect(index.perComic.map((c) => c.comicSlug), ['a', 'b']);
    expect(identical(index.perComic[1], b), isTrue);
    expect(index.countOf('a'), 3);
    expect(index.finishedCountOf('a'), 3);
  });
}
