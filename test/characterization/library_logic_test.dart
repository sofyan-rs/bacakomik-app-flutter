import 'package:bacakomik_app/core/bloc/bookmark_cubit/bookmark_cubit.dart';
import 'package:bacakomik_app/core/bloc/history_cubit/history_cubit.dart';
import 'package:bacakomik_app/core/models/bookmark_model.dart';
import 'package:bacakomik_app/core/models/comic_details_model/comic_details_model.dart';
import 'package:bacakomik_app/core/models/history_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fixtures/legacy_storage_fixtures.dart';
import '../helpers/hydrated_storage.dart';

final details = ComicDetailsModel.fromMap(legacyComicDetails);

HistoryModel history(String slug, String comicSlug, int readDate) =>
    HistoryModel(
      slug: slug,
      chapterNumber: slug.split('/').last,
      readDate: DateTime.fromMillisecondsSinceEpoch(readDate),
      comicDetails: details,
      comicSlug: comicSlug,
    );

BookmarkModel bookmark(String slug, String title, int updatedDate) =>
    BookmarkModel(
      slug: slug,
      comicDetails: details.copyWith(title: title),
      updatedDate: DateTime.fromMillisecondsSinceEpoch(updatedDate),
    );

void main() {
  setUp(mockHydratedStorage);

  group('HistoryCubit', () {
    late HistoryCubit cubit;

    setUp(() {
      cubit = HistoryCubit()
        ..setHistory([
          history('a/1', 'a', 100),
          history('b/1', 'b', 300),
          history('a/2', 'a', 200),
        ]);
    });

    test('addHistory puts entry first and replaces same slug', () {
      cubit.addHistory(
        slug: 'a/1',
        chapterNumber: '1',
        comicDetails: details,
        comicSlug: 'a',
      );

      expect(cubit.state.map((h) => h.slug), ['a/1', 'b/1', 'a/2']);
    });

    test('setHistory replaces existing slugs and appends', () {
      cubit.setHistory([history('a/1', 'a', 999), history('c/1', 'c', 50)]);

      expect(cubit.state.map((h) => h.slug), ['b/1', 'a/2', 'a/1', 'c/1']);
    });

    test('latestHistory is newest by readDate', () {
      expect(cubit.latestHistory.slug, 'b/1');
    });

    test('getLatestHistoryBySlug and count per comic', () {
      expect(cubit.getLatestHistoryBySlug('a')!.slug, 'a/2');
      expect(cubit.getLatestHistoryBySlug('z'), isNull);
      expect(cubit.getHistoryCountBySlug('a'), 2);
    });

    test('latestHistories keeps newest entry per comic, newest first', () {
      expect(
        cubit.latestHistories.map((h) => h.latestHistory.slug),
        ['b/1', 'a/2'],
      );
    });

    test('read-only getters do not reorder state', () {
      final before = cubit.state.map((h) => h.slug).toList();
      cubit
        ..latestHistory
        ..latestHistories
        ..getLatestHistoryBySlug('a');

      expect(cubit.state.map((h) => h.slug), before);
    });

    test('remove variants', () {
      cubit.removeHistory('b/1');
      expect(cubit.state.map((h) => h.slug), ['a/1', 'a/2']);

      cubit.removeHistoryBySlug('a');
      expect(cubit.state, isEmpty);
    });
  });

  group('BookmarkCubit', () {
    late BookmarkCubit cubit;

    setUp(() {
      cubit = BookmarkCubit()
        ..setBookmark([
          bookmark('a', 'Alpha', 100),
          bookmark('b', 'Beta', 300),
          bookmark('c', 'Gamma', 200),
        ]);
    });

    test('addBookmark puts entry first', () {
      cubit.addBookmark(details, 'd');

      expect(cubit.state.first.slug, 'd');
      expect(cubit.isBookmark('d'), isTrue);
    });

    test('searchBookmark filters by lowercase title, newest first', () {
      expect(cubit.searchBookmark('a').map((b) => b.slug), ['b', 'c', 'a']);
      expect(cubit.searchBookmark('gam').map((b) => b.slug), ['c']);
    });

    test('removeBookmarkList', () {
      cubit.removeBookmarkList(['a', 'c']);

      expect(cubit.state.map((b) => b.slug), ['b']);
    });
  });
}
