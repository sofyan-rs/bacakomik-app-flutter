import 'package:bacakomik_app/core/domain/entities/comic_details.dart';
import 'package:bacakomik_app/core/error/failures.dart';
import 'package:bacakomik_app/core/usecase/usecase.dart';
import 'package:bacakomik_app/core/utils/clock.dart';
import 'package:bacakomik_app/features/bookmark/domain/entities/bookmark.dart';
import 'package:bacakomik_app/features/bookmark/domain/repositories/bookmark_repository.dart';
import 'package:bacakomik_app/features/category/domain/entities/category.dart';
import 'package:bacakomik_app/features/category/domain/repositories/category_repository.dart';
import 'package:bacakomik_app/features/history/domain/repositories/history_repository.dart';
import 'package:bacakomik_app/features/migration/domain/repositories/pending_read_repository.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

typedef MigrateComicParams = ({String from, String to, ComicDetails details});

/// Moves a comic's bookmark and read history from one source to another,
/// like Mihon's migrate: the bookmark under [MigrateComicParams.from] is
/// replaced by one under [MigrateComicParams.to], and each read chapter
/// moves to the chapter with the same number in the new source. Chapters
/// the new source lacks are dropped. The comic keeps its categories, joined
/// with those of a bookmark it replaces under [MigrateComicParams.to].
/// Progress an import left waiting for the old key (matched by chapter
/// number, so valid in any source) moves to the new one, joined with what
/// already waits there.
@injectable
class MigrateComic implements UseCase<Unit, MigrateComicParams> {
  const MigrateComic(
    this._bookmarks,
    this._history,
    this._categories,
    this._clock, [
    this._pending,
  ]);

  final BookmarkRepository _bookmarks;
  final HistoryRepository _history;
  final CategoryRepository _categories;
  final Clock _clock;

  /// Optional only so the generated DI code built before it was added still
  /// compiles; registered, it is always given.
  final PendingReadRepository? _pending;

  @override
  Future<Either<Failure, Unit>> call(MigrateComicParams params) async {
    final (:from, :to, :details) = params;
    final bookmarks = await _bookmarks.getBookmarks();
    if (bookmarks case Left(value: final failure)) return left(failure);
    final history = await _history.getHistory();
    if (history case Left(value: final failure)) return left(failure);
    final categories = await _categories.getComicCategories();
    if (categories case Left(value: final failure)) return left(failure);
    // A comic already bookmarked in the new source keeps its categories too.
    final byComic = categories.getOrElse((_) => const {});
    final categoryIds = {
      ...?byComic[to]?.categoryIds,
      ...?byComic[from]?.categoryIds,
    }.toList();

    final chapters = {for (final c in details.chapters) c.number: c.slug};
    final moved = [
      for (final h in history.getOrElse((_) => const []))
        if (h.comicSlug == from)
          if (chapters[h.chapterNumber] case final slug?)
            h.copyWith(slug: slug, comicSlug: to, comicDetails: details),
    ];

    final now = _clock.now();
    final steps = <Future<Either<Failure, Unit>> Function()>[
      () => _bookmarks.saveBookmarks([
        Bookmark(
          slug: to,
          comicDetails: details,
          updatedDate: now,
          addedDate:
              _earliestAdded(bookmarks.getOrElse((_) => const []), {
                from,
                to,
              }) ??
              now,
        ),
      ]),
      if (moved.isNotEmpty) () => _history.saveHistory(moved),
      if (categoryIds.isNotEmpty)
        () => _categories.saveComicCategories([
          ComicCategories(slug: to, categoryIds: categoryIds, updatedDate: now),
        ]),
      if (_pending case final pending?) () => _movePending(pending, from, to),
      () => _history.removeComicHistory(from),
      () => _bookmarks.removeBookmarks([from]),
    ];
    for (final step in steps) {
      final result = await step();
      if (result.isLeft()) return result;
    }
    return right(unit);
  }

  Future<Either<Failure, Unit>> _movePending(
    PendingReadRepository pending,
    String from,
    String to,
  ) async {
    final moving = await pending.pendingOf(from);
    if (moving case Left(value: final failure)) return left(failure);
    final read = moving.getOrElse((_) => null);
    if (read == null || from == to) return right(unit);
    final waiting = await pending.pendingOf(to);
    if (waiting case Left(value: final failure)) return left(failure);
    final merged = switch (waiting.getOrElse((_) => null)) {
      final there? => there.merge(read),
      null => read,
    };
    final saved = await pending.save({to: merged});
    if (saved.isLeft()) return saved;
    return pending.remove(from);
  }
}

/// When the earliest of the bookmarks under [slugs] was added (its
/// [Bookmark.updatedDate] if that was not stored), so a migrated comic keeps
/// its place when sorted by date added.
DateTime? _earliestAdded(List<Bookmark> bookmarks, Set<String> slugs) {
  DateTime? earliest;
  for (final b in bookmarks) {
    if (!slugs.contains(b.slug)) continue;
    final added = b.addedDate ?? b.updatedDate;
    if (earliest == null || added.isBefore(earliest)) earliest = added;
  }
  return earliest;
}

/// Library entries that look like the same series as [title] in another
/// source: equal titles once case, spacing and punctuation are ignored.
List<Bookmark> sameSeries(List<Bookmark> bookmarks, String key, String title) {
  final wanted = normalizeTitle(title);
  if (wanted.isEmpty) return const [];
  return [
    for (final b in bookmarks)
      if (b.slug != key && normalizeTitle(b.comicDetails.title) == wanted) b,
  ];
}

/// Ignores case, spacing and punctuation, which differ between sources
/// (`’` and `'`, `:` and `-`).
String normalizeTitle(String title) =>
    title.toLowerCase().replaceAll(RegExp(r'[^\p{L}\p{N}]', unicode: true), '');
