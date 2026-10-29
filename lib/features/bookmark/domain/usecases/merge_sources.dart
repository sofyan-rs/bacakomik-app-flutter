import 'package:bacakomik_app/core/domain/entities/comic_details.dart';
import 'package:bacakomik_app/core/error/failures.dart';
import 'package:bacakomik_app/core/usecase/usecase.dart';
import 'package:bacakomik_app/core/utils/clock.dart';
import 'package:bacakomik_app/features/bookmark/domain/entities/bookmark.dart';
import 'package:bacakomik_app/features/bookmark/domain/entities/merged_chapters.dart';
import 'package:bacakomik_app/features/bookmark/domain/repositories/bookmark_repository.dart';
import 'package:bacakomik_app/features/bookmark/domain/usecases/migrate_comic.dart';
import 'package:bacakomik_app/features/category/domain/entities/category.dart';
import 'package:bacakomik_app/features/category/domain/repositories/category_repository.dart';
import 'package:bacakomik_app/features/comic_detail/domain/repositories/comic_detail_repository.dart';
import 'package:bacakomik_app/features/history/domain/entities/read_history.dart';
import 'package:bacakomik_app/features/history/domain/repositories/history_repository.dart';
import 'package:bacakomik_app/features/migration/domain/repositories/pending_read_repository.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

/// The chapter lists of a merged bookmark's sources, fetched in parallel
/// and merged ([mergeChapters], one per number with [dedupe]). A source
/// that fails keeps the chapters [stored] has from it; fails only when
/// every source fails.
///
/// [first], when given, is the result of the first source, fetched by the
/// caller (with its details).
@injectable
class FetchMergedChapters {
  const FetchMergedChapters(this._comicDetails);

  final ComicDetailRepository _comicDetails;

  Future<Either<Failure, List<Chapter>>> call(
    List<String> keys,
    List<Chapter> stored, {
    Future<Either<Failure, List<Chapter>>>? first,
    bool dedupe = true,
  }) async {
    final results = await Future.wait([
      for (final (i, key) in keys.indexed)
        i == 0 && first != null ? first : _comicDetails.getChapters(key),
    ]);
    Failure? failure;
    final lists = [
      for (final (i, result) in results.indexed)
        result.fold((f) {
          failure ??= f;
          return chaptersOf(stored, keys[i]);
        }, (chapters) => chapters),
    ];
    if (failure case final failure? when results.every((r) => r.isLeft())) {
      return left(failure);
    }
    return right(mergeChapters(lists, dedupe: dedupe));
  }
}

typedef AlignMergedHistoryParams = ({String key, List<Chapter> chapters});

/// Points the read chapters of the merged bookmark [key] at the chapters
/// its list now has: an entry whose chapter the list took from another
/// source (the sources were reordered, or one stopped having it) moves to
/// the chapter with the same number, as a migration would. Returns whether
/// the history changed.
@injectable
class AlignMergedHistory implements UseCase<bool, AlignMergedHistoryParams> {
  const AlignMergedHistory(this._history);

  final HistoryRepository _history;

  @override
  Future<Either<Failure, bool>> call(AlignMergedHistoryParams params) async {
    final (:key, :chapters) = params;
    final history = await _history.getHistory();
    if (history case Left(value: final failure)) return left(failure);
    final entries = [
      for (final h in history.getOrElse((_) => const []))
        if (h.comicSlug == key) h,
    ];
    final listed = {for (final c in chapters) c.slug};
    // Of several chapters of one number (duplicates kept), the first.
    final slugs = <String, String>{};
    for (final c in chapters) {
      slugs.putIfAbsent(c.number, () => c.slug);
    }
    final read = {for (final h in entries) h.slug};
    final moved = <ReadHistory>[];
    final removed = <String>[];
    // Newest first: of several entries of one number, the newest moves.
    for (final h in entries) {
      if (listed.contains(h.slug)) continue;
      final slug = slugs[h.chapterNumber];
      if (slug == null || slug == h.slug) continue;
      removed.add(h.slug);
      if (read.add(slug)) moved.add(h.copyWith(slug: slug));
    }
    if (removed.isEmpty) return right(false);
    if (moved.isNotEmpty) {
      final saved = await _history.saveHistory(moved);
      if (saved case Left(value: final failure)) return left(failure);
    }
    final result = await _history.removeHistory(removed);
    return result.map((_) => true);
  }
}

typedef MergeComicParams = ({String into, String add, ComicDetails? details});

/// Merges the series [MergeComicParams.add] into the bookmark
/// [MergeComicParams.into], last in its order. When [add] is bookmarked
/// too, that bookmark goes: its sources, read history, categories and
/// imported progress join [into], which keeps the earliest date added.
/// [details] are [add]'s, when the caller has them; otherwise its chapter
/// list is fetched (or taken from its bookmark).
@injectable
class MergeComic implements UseCase<Unit, MergeComicParams> {
  const MergeComic(
    this._bookmarks,
    this._history,
    this._categories,
    this._comicDetails,
    this._pending,
    this._align,
    this._clock,
  );

  final BookmarkRepository _bookmarks;
  final HistoryRepository _history;
  final CategoryRepository _categories;
  final ComicDetailRepository _comicDetails;
  final PendingReadRepository _pending;
  final AlignMergedHistory _align;
  final Clock _clock;

  @override
  Future<Either<Failure, Unit>> call(MergeComicParams params) async {
    final (:into, :add, :details) = params;
    final target = await _bookmarks.getBookmark(into);
    if (target case Left(value: final failure)) return left(failure);
    final bookmark = target.getOrElse((_) => null);
    if (bookmark == null) return left(const CacheFailure('Not bookmarked'));
    if (bookmark.sourceKeys.contains(add)) return right(unit);
    final other = await _bookmarks.getBookmark(add);
    if (other case Left(value: final failure)) return left(failure);
    final added = other.getOrElse((_) => null);

    final List<Chapter> addedChapters;
    if (details != null) {
      addedChapters = details.chapters;
    } else if (added != null) {
      addedChapters = added.comicDetails.chapters;
    } else {
      final fetched = await _comicDetails.getChapters(add);
      if (fetched case Left(value: final failure)) return left(failure);
      addedChapters = fetched.getOrElse((_) => const []);
    }

    final keys = [
      ...bookmark.sourceKeys,
      for (final k in added?.sourceKeys ?? [add])
        if (!bookmark.sourceKeys.contains(k)) k,
    ];
    final stored = [...bookmark.comicDetails.chapters, ...addedChapters];
    final chapters = mergeChapters([
      for (final k in keys) chaptersOf(stored, k),
    ], dedupe: !bookmark.keepDuplicates);
    final merged = bookmark.copyWith(
      comicDetails: bookmark.comicDetails.copyWith(chapters: chapters),
      mergedKeys: keys,
      updatedDate: _clock.now(),
      addedDate: switch ((bookmark.addedDate, added?.addedDate)) {
        (final a?, final b?) => a.isBefore(b) ? a : b,
        (final a, final b) => a ?? b,
      },
    );

    final steps = <Future<Either<Failure, Unit>> Function()>[
      () => _bookmarks.saveBookmarks([merged]),
      if (added != null) ...[
        () => _moveHistory(add, into, merged.comicDetails),
        () => _joinCategories(add, into),
        () => movePendingReads(_pending, add, into),
        () => _bookmarks.removeBookmarks([add]),
      ],
      () async =>
          (await _align((key: into, chapters: chapters))).map((_) => unit),
    ];
    for (final step in steps) {
      final result = await step();
      if (result.isLeft()) return result;
    }
    return right(unit);
  }

  /// The entries of [from] become [to]'s, under the same chapter slugs.
  Future<Either<Failure, Unit>> _moveHistory(
    String from,
    String to,
    ComicDetails details,
  ) async {
    final history = await _history.getHistory();
    if (history case Left(value: final failure)) return left(failure);
    final moved = [
      for (final h in history.getOrElse((_) => const []))
        if (h.comicSlug == from)
          h.copyWith(comicSlug: to, comicDetails: details),
    ];
    if (moved.isNotEmpty) {
      final saved = await _history.saveHistory(moved);
      if (saved.isLeft()) return saved;
    }
    // Drops the record of [from], now without entries.
    return _history.removeComicHistory(from);
  }

  Future<Either<Failure, Unit>> _joinCategories(String from, String to) async {
    final categories = await _categories.getComicCategories();
    if (categories case Left(value: final failure)) return left(failure);
    final byComic = categories.getOrElse((_) => const {});
    final ids = {
      ...?byComic[to]?.categoryIds,
      ...?byComic[from]?.categoryIds,
    }.toList();
    if (ids.isEmpty) return right(unit);
    return _categories.saveComicCategories([
      ComicCategories(slug: to, categoryIds: ids, updatedDate: _clock.now()),
    ]);
  }
}

typedef SetMergedSourcesParams = ({
  String key,
  List<String>? keys,
  bool? keepDuplicates,
});

/// Reorders or removes the sources of the merged bookmark
/// [SetMergedSourcesParams.key] ([SetMergedSourcesParams.keys] keeps the
/// bookmark's own key), or turns [Bookmark.keepDuplicates] on or off; null
/// leaves each as it is. The chapter list follows once the comic is loaded
/// again. Chapters of a removed source, and duplicates turned off, leave
/// the list now.
@injectable
class SetMergedSources implements UseCase<Unit, SetMergedSourcesParams> {
  const SetMergedSources(this._bookmarks);

  final BookmarkRepository _bookmarks;

  @override
  Future<Either<Failure, Unit>> call(SetMergedSourcesParams params) async {
    final (:key, :keys, :keepDuplicates) = params;
    final result = await _bookmarks.updateBookmark(key, (current) {
      final kept = [
        for (final k in keys ?? current.sourceKeys)
          if (current.sourceKeys.contains(k)) k,
      ];
      if (!kept.contains(key)) return null;
      final duplicates = keepDuplicates ?? current.keepDuplicates;
      final chapters = mergeChapters([
        for (final k in kept) chaptersOf(current.comicDetails.chapters, k),
      ], dedupe: !duplicates);
      return current.copyWith(
        mergedKeys: kept.length > 1 ? kept : const [],
        keepDuplicates: duplicates,
        comicDetails: current.comicDetails.copyWith(chapters: chapters),
      );
    });
    return result.map((_) => unit);
  }
}
