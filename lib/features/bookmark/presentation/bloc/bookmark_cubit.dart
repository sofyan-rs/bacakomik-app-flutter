import 'dart:async';
import 'dart:collection';

import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:bacakomik_app/core/domain/entities/comic_details.dart';
import 'package:bacakomik_app/core/error/failures.dart';
import 'package:bacakomik_app/core/notifications/progress_notifier.dart';
import 'package:bacakomik_app/core/usecase/usecase.dart';
import 'package:bacakomik_app/core/utils/clock.dart';
import 'package:bacakomik_app/features/bookmark/domain/entities/bookmark.dart';
import 'package:bacakomik_app/features/bookmark/domain/usecases/bookmark_usecases.dart';
import 'package:bacakomik_app/features/bookmark/domain/usecases/migrate_comic.dart';
import 'package:bacakomik_app/features/bookmark/domain/usecases/refresh_bookmark.dart';
import 'package:bacakomik_app/features/migration/domain/usecases/apply_pending_reads.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

/// Bookmarked comics, newest [Bookmark.updatedDate] first.
@injectable
class BookmarkCubit extends Cubit<List<Bookmark>> {
  BookmarkCubit(
    this._getBookmarks,
    this._saveBookmarks,
    this._removeBookmarks,
    this._refreshBookmark,
    this._migrateComic,
    this._completeImportedComic,
    this._notifier,
    this._clock,
  ) : super(const []);

  final GetBookmarks _getBookmarks;
  final SaveBookmarks _saveBookmarks;
  final RemoveBookmarks _removeBookmarks;
  final RefreshBookmark _refreshBookmark;
  final MigrateComic _migrateComic;
  final CompleteImportedComic _completeImportedComic;
  final ProgressNotifier _notifier;
  final Clock _clock;

  Future<void> load() async {
    final result = await _getBookmarks(const NoParams());
    result.fold(_log, emit);
  }

  Future<void> addBookmark(ComicDetails comic, String slug) => _thenReload(
    _saveBookmarks([
      Bookmark(slug: slug, comicDetails: comic, updatedDate: _clock.now()),
    ]),
  );

  Future<void> removeBookmark(String slug) => removeBookmarkList([slug]);

  Future<void> removeBookmarkList(List<String> slugs) =>
      _thenReload(_removeBookmarks([...slugs]));

  /// Bookmarks waiting to be refreshed, in order.
  final _refreshQueue = Queue<Bookmark>();

  /// Slugs queued or checked in the current run, so none is checked twice.
  final _refreshSeen = <String>{};
  var _refreshDone = 0;
  var _refreshUpdated = 0;
  Future<void>? _refreshRun;

  /// Pull-to-refresh: checks [slugs] (the bookmarks of the open group) for
  /// new chapters, with a progress notification while it runs. Called again
  /// before the run ends, the new slugs join the queue and the total grows.
  /// Completes when the queue is empty.
  Future<void> updateBookmarkList(Iterable<String> slugs) {
    final wanted = slugs.toSet();
    for (final bookmark in state) {
      if (wanted.contains(bookmark.slug) && _refreshSeen.add(bookmark.slug)) {
        _refreshQueue.add(bookmark);
      }
    }
    return _refreshRun ??= _drainRefreshQueue().whenComplete(() {
      _refreshRun = null;
      _refreshSeen.clear();
      _refreshDone = 0;
      _refreshUpdated = 0;
    });
  }

  Future<void> _drainRefreshQueue() async {
    const id = ProgressIds.bookmarkRefresh;
    while (_refreshQueue.isNotEmpty) {
      unawaited(
        _notifier.progress(
          id,
          title: AppText.updatingBookmarks,
          done: _refreshDone,
          total: _refreshDone + _refreshQueue.length,
        ),
      );
      final result = await _refreshBookmark(_refreshQueue.removeFirst());
      _refreshDone++;
      if (result.getOrElse((failure) {
        _log(failure);
        return false;
      })) {
        _refreshUpdated++;
        await load();
      }
    }
    await _notifier.finish(
      id,
      title: _refreshUpdated > 0 ? AppText.bookmarksUpdated : null,
      body:
          '${AppText.count(_refreshUpdated, AppText.comic, AppText.comics)} '
          '${AppText.haveNewChapters}',
    );
  }

  bool isBookmark(String slug) => state.any((b) => b.slug == slug);

  /// Bookmarks of the same series from other sources, by title.
  List<Bookmark> sameSeriesAs(String slug, String title) =>
      sameSeries(state, slug, title);

  /// Moves the bookmark and read history of [from] to [to]. The caller
  /// reloads history.
  Future<void> migrate({
    required String from,
    required String to,
    required ComicDetails details,
  }) => _thenReload(_migrateComic((from: from, to: to, details: details)));

  /// Called when [key]'s details loaded from its source: an imported
  /// bookmark gets them, and imported reading progress is applied. Returns
  /// whether the history changed; the caller reloads it.
  Future<bool> comicLoaded(String key, ComicDetails details) async {
    final result = await _completeImportedComic((key: key, details: details));
    await load();
    return result.getOrElse((failure) {
      _log(failure);
      return false;
    });
  }

  /// Bookmarks whose title contains [keyword] (case-insensitive on title).
  List<Bookmark> searchBookmark(String keyword) => state
      .where((b) => b.comicDetails.title.toLowerCase().contains(keyword))
      .toList();

  Future<void> _thenReload(Future<Either<Failure, Unit>> action) async {
    (await action).fold(_log, (_) {});
    await load();
  }

  void _log(Failure failure) => debugPrint('BookmarkCubit: $failure');
}
