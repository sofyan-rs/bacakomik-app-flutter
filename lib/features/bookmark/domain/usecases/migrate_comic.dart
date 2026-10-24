import 'package:bacakomik_app/core/domain/entities/comic_details.dart';
import 'package:bacakomik_app/core/error/failures.dart';
import 'package:bacakomik_app/core/usecase/usecase.dart';
import 'package:bacakomik_app/core/utils/clock.dart';
import 'package:bacakomik_app/features/bookmark/domain/entities/bookmark.dart';
import 'package:bacakomik_app/features/bookmark/domain/repositories/bookmark_repository.dart';
import 'package:bacakomik_app/features/category/domain/entities/category.dart';
import 'package:bacakomik_app/features/category/domain/repositories/category_repository.dart';
import 'package:bacakomik_app/features/history/domain/repositories/history_repository.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

typedef MigrateComicParams = ({String from, String to, ComicDetails details});

/// Moves a comic's bookmark and read history from one source to another,
/// like Mihon's migrate: the bookmark under [MigrateComicParams.from] is
/// replaced by one under [MigrateComicParams.to], and each read chapter
/// moves to the chapter with the same number in the new source. Chapters
/// the new source lacks are dropped. The comic keeps its categories.
@injectable
class MigrateComic implements UseCase<Unit, MigrateComicParams> {
  const MigrateComic(
    this._bookmarks,
    this._history,
    this._categories,
    this._clock,
  );

  final BookmarkRepository _bookmarks;
  final HistoryRepository _history;
  final CategoryRepository _categories;
  final Clock _clock;

  @override
  Future<Either<Failure, Unit>> call(MigrateComicParams params) async {
    final (:from, :to, :details) = params;
    final history = await _history.getHistory();
    if (history case Left(value: final failure)) return left(failure);
    final categories = await _categories.getComicCategories();
    if (categories case Left(value: final failure)) return left(failure);
    final categoryIds =
        categories.getOrElse((_) => const {})[from]?.categoryIds ?? const [];

    final chapters = {for (final c in details.chapters) c.number: c.slug};
    final moved = [
      for (final h in history.getOrElse((_) => const []))
        if (h.comicSlug == from)
          if (chapters[h.chapterNumber] case final slug?)
            h.copyWith(slug: slug, comicSlug: to, comicDetails: details),
    ];

    final steps = <Future<Either<Failure, Unit>> Function()>[
      () => _bookmarks.saveBookmarks([
        Bookmark(slug: to, comicDetails: details, updatedDate: _clock.now()),
      ]),
      if (moved.isNotEmpty) () => _history.saveHistory(moved),
      if (categoryIds.isNotEmpty)
        () => _categories.saveComicCategories([
          ComicCategories(
            slug: to,
            categoryIds: categoryIds,
            updatedDate: _clock.now(),
          ),
        ]),
      () => _history.removeComicHistory(from),
      () => _bookmarks.removeBookmarks([from]),
    ];
    for (final step in steps) {
      final result = await step();
      if (result.isLeft()) return result;
    }
    return right(unit);
  }
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
