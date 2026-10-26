import 'package:bacakomik_app/core/domain/entities/comic_details.dart';
import 'package:bacakomik_app/core/error/failures.dart';
import 'package:bacakomik_app/core/usecase/usecase.dart';
import 'package:bacakomik_app/features/bookmark/domain/repositories/bookmark_repository.dart';
import 'package:bacakomik_app/features/comic_detail/domain/repositories/comic_detail_repository.dart';
import 'package:bacakomik_app/features/download/domain/repositories/download_repository.dart';
import 'package:bacakomik_app/features/history/domain/repositories/history_repository.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

/// Params: series slug. When the request fails, a comic in the library
/// opens from its stored details, so it can still be browsed offline. The
/// stored copy is tried from downloads, then bookmarks, then history.
@injectable
class GetComicDetails implements UseCase<ComicDetails, String> {
  const GetComicDetails(
    this._repository,
    this._downloads,
    this._bookmarks,
    this._history,
  );

  final ComicDetailRepository _repository;
  final DownloadRepository _downloads;
  final BookmarkRepository _bookmarks;
  final HistoryRepository _history;

  /// [onSeries]: see [ComicDetailRepository.getComicDetails].
  @override
  Future<Either<Failure, ComicDetails>> call(
    String slug, {
    void Function(ComicDetails details)? onSeries,
  }) async {
    final result = await _repository.getComicDetails(slug, onSeries: onSeries);
    if (result.isRight()) return result;
    final stored = await _stored(slug);
    return stored != null ? right(stored) : result;
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
