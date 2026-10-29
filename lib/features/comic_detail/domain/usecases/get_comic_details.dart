import 'package:bacakomik_app/core/domain/entities/comic_details.dart';
import 'package:bacakomik_app/core/error/failures.dart';
import 'package:bacakomik_app/core/usecase/usecase.dart';
import 'package:bacakomik_app/features/bookmark/domain/entities/bookmark.dart';
import 'package:bacakomik_app/features/bookmark/domain/repositories/bookmark_repository.dart';
import 'package:bacakomik_app/features/bookmark/domain/usecases/merge_sources.dart';
import 'package:bacakomik_app/features/comic_detail/domain/repositories/comic_detail_repository.dart';
import 'package:bacakomik_app/features/download/domain/repositories/download_repository.dart';
import 'package:bacakomik_app/features/history/domain/repositories/history_repository.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

/// Params: series slug. When the request fails, a comic in the library
/// opens from its stored details, so it can still be browsed offline. The
/// stored copy is tried from downloads, then bookmarks, then history.
///
/// A merged bookmark ([Bookmark.isMerged]) loads its details from its
/// first source and its chapters from all of them ([FetchMergedChapters]).
@injectable
class GetComicDetails implements UseCase<LoadedComic, String> {
  const GetComicDetails(
    this._repository,
    this._downloads,
    this._bookmarks,
    this._history,
    this._mergedChapters,
  );

  final ComicDetailRepository _repository;
  final DownloadRepository _downloads;
  final BookmarkRepository _bookmarks;
  final HistoryRepository _history;
  final FetchMergedChapters _mergedChapters;

  /// [onSeries]: see [ComicDetailRepository.getComicDetails].
  @override
  Future<Either<Failure, LoadedComic>> call(
    String slug, {
    void Function(ComicDetails details)? onSeries,
  }) async {
    final bookmark = (await _bookmarks.getBookmark(slug))
        .getOrElse((_) => null);
    final result = bookmark != null && bookmark.isMerged
        ? await _merged(bookmark, onSeries)
        : await _repository.getComicDetails(slug, onSeries: onSeries);
    if (result case Right(value: final details)) {
      return right((details: details, stored: false));
    }
    final stored = await _stored(slug);
    if (stored != null) return right((details: stored, stored: true));
    return result.map((details) => (details: details, stored: false));
  }

  Future<Either<Failure, ComicDetails>> _merged(
    Bookmark bookmark,
    void Function(ComicDetails details)? onSeries,
  ) async {
    final keys = bookmark.sourceKeys;
    final stored = bookmark.comicDetails;
    final first = _repository.getComicDetails(keys.first, onSeries: onSeries);
    final chapters = await _mergedChapters(
      keys,
      stored.chapters,
      first: first.then((r) => r.map((d) => d.chapters)),
      dedupe: !bookmark.keepDuplicates,
    );
    final details = (await first).getOrElse((_) => stored);
    return chapters.map((chapters) => details.copyWith(chapters: chapters));
  }

  Future<ComicDetails?> _stored(String slug) async {
    if (await _downloads.getOfflineComic(slug) case final details?) {
      return details;
    }
    final bookmarks = (await _bookmarks.getBookmarks()).getOrElse(
      (_) => const [],
    );
    for (final bookmark in bookmarks) {
      if (bookmark.slug == slug) return bookmark.comicDetails;
    }
    final history = (await _history.getHistory()).getOrElse((_) => const []);
    for (final entry in history) {
      if (entry.comicSlug == slug) return entry.comicDetails;
    }
    return null;
  }
}

/// [stored]: the request failed and [details] is the library's copy.
typedef LoadedComic = ({ComicDetails details, bool stored});
