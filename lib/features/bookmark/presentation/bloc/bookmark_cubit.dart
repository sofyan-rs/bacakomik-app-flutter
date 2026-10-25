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

/// Bookmarked comics, newest [Bookmark.updatedDate] first
/// ([compareBookmarksNewestFirst]).
///
/// Adding, removing, refreshing and completing an import update the list in
/// memory to what [load] would read back; a failed write reloads. Call
/// [load] after the library changed elsewhere (sync, import, restore).
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
  ) : super(const []) {
    _cancelRequests = _notifier.cancelRequests
        .where((id) => id == ProgressIds.bookmarkRefresh)
        .listen((_) => cancelRefresh());
  }

  late final StreamSubscription<int> _cancelRequests;

  final GetBookmarks _getBookmarks;
  final SaveBookmarks _saveBookmarks;
  final RemoveBookmarks _removeBookmarks;
  final RefreshBookmark _refreshBookmark;
  final MigrateComic _migrateComic;
  final CompleteImportedComic _completeImportedComic;
  final ProgressNotifier _notifier;
  final Clock _clock;

  /// Counts in-memory edits, so a [load] that read the box before an edit
  /// landed reads again instead of dropping it.
  var _edits = 0;

  Future<void> load() async {
    while (true) {
      final edits = _edits;
      final result = await _getBookmarks(const NoParams());
      if (isClosed) return;
      if (edits != _edits) continue;
      return result.fold(_log, emit);
    }
  }

  Future<void> addBookmark(ComicDetails comic, String slug) async {
    final now = _clock.now();
    final bookmark = Bookmark(
      slug: slug,
      comicDetails: comic,
      updatedDate: now,
      addedDate: now,
    );
    final result = await _saveBookmarks([bookmark]);
    if (result case Left(value: final failure)) {
      _log(failure);
      return load();
    }
    _put(bookmark);
  }

  Future<void> removeBookmark(String slug) => removeBookmarkList([slug]);

  Future<void> removeBookmarkList(List<String> slugs) async {
    final result = await _removeBookmarks([...slugs]);
    if (result case Left(value: final failure)) {
      _log(failure);
      return load();
    }
    final removed = slugs.toSet();
    final kept = [
      for (final b in state)
        if (!removed.contains(b.slug)) b,
    ];
    if (kept.length != state.length) _edit(kept);
  }

  /// [state] with [saved] stored: replaced by slug and placed in order,
  /// dates to the millisecond as they are read back.
  @visibleForTesting
  static List<Bookmark> withSaved(List<Bookmark> current, Bookmark saved) {
    DateTime ms(DateTime d) =>
        DateTime.fromMillisecondsSinceEpoch(d.millisecondsSinceEpoch);
    final bookmark = saved.copyWith(
      updatedDate: ms(saved.updatedDate),
      addedDate: switch (saved.addedDate) {
        final added? => ms(added),
        null => null,
      },
    );
    final list = [
      for (final b in current)
        if (b.slug != bookmark.slug) b,
    ];
    var low = 0, high = list.length;
    while (low < high) {
      final mid = (low + high) >> 1;
      if (compareBookmarksNewestFirst(list[mid], bookmark) < 0) {
        low = mid + 1;
      } else {
        high = mid;
      }
    }
    return list..insert(low, bookmark);
  }

  void _put(Bookmark saved) => _edit(withSaved(state, saved));

  void _edit(List<Bookmark> bookmarks) {
    if (isClosed) return;
    _edits++;
    emit(bookmarks);
  }

  final _historyChanges = StreamController<void>.broadcast();

  /// Fires when a refresh wrote imported reading progress to the history,
  /// so whoever shows the history reloads it.
  Stream<void> get historyChanges => _historyChanges.stream;

  @override
  Future<void> close() async {
    await _cancelRequests.cancel();
    refreshing.dispose();
    await _historyChanges.close();
    return super.close();
  }

  /// Bookmarks waiting to be refreshed, in order.
  final _refreshQueue = Queue<Bookmark>();

  /// Slugs queued or checked in the current run, so none is checked twice.
  final _refreshSeen = <String>{};
  var _refreshDone = 0;
  var _refreshUpdated = 0;
  Future<void>? _refreshRun;

  /// Whether a refresh run is going; Bookmarks shows a stop button.
  final refreshing = ValueNotifier<bool>(false);

  /// Completed to stop the current run.
  Completer<void>? _refreshCancel;

  /// A comic that takes longer is skipped, so one stuck site cannot hold
  /// up the rest.
  static const refreshTimeout = Duration(seconds: 90);

  /// Stops the refresh run: the comic being checked is abandoned and the
  /// rest of the queue dropped. Comics checked so far keep their updates.
  void cancelRefresh() {
    _refreshQueue.clear();
    if (!(_refreshCancel?.isCompleted ?? true)) _refreshCancel!.complete();
  }

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
    if (_refreshRun == null) refreshing.value = true;
    return _refreshRun ??= _drainRefreshQueue().whenComplete(() {
      refreshing.value = false;
      _refreshRun = null;
      _refreshSeen.clear();
      _refreshDone = 0;
      _refreshUpdated = 0;
    });
  }

  Future<void> _drainRefreshQueue() async {
    const id = ProgressIds.bookmarkRefresh;
    const skipped = Right<Failure, RefreshResult>((
      saved: null,
      historyChanged: false,
      failure: null,
    ));
    final cancel = _refreshCancel = Completer<void>();
    while (_refreshQueue.isNotEmpty && !cancel.isCompleted) {
      unawaited(
        _notifier.progress(
          id,
          title: AppText.updatingBookmarks,
          done: _refreshDone,
          total: _refreshDone + _refreshQueue.length,
          cancelable: true,
        ),
      );
      final bookmark = _refreshQueue.removeFirst();
      final result = await Future.any([
        _refreshBookmark(bookmark).timeout(
          refreshTimeout,
          onTimeout: () {
            debugPrint('BookmarkCubit: ${bookmark.slug} timed out');
            return skipped;
          },
        ),
        cancel.future.then((_) => skipped),
      ]);
      _refreshDone++;
      final (:saved, :historyChanged, :failure) = result.getOrElse(
        (failure) => (saved: null, historyChanged: false, failure: failure),
      );
      if (failure != null) debugPrint('Refresh ${bookmark.slug}: $failure');
      if (historyChanged) _historyChanges.add(null);
      if (saved != null) {
        _refreshUpdated++;
        _put(saved);
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
  /// whether the history changed; the caller reloads it. The bookmarks
  /// change only when an imported one was completed.
  Future<bool> comicLoaded(String key, ComicDetails details) async {
    final result = await _completeImportedComic((key: key, details: details));
    switch (result) {
      case Left(value: final failure):
        _log(failure);
        await load();
        return false;
      case Right(value: (:final bookmark, :final historyChanged)):
        if (bookmark != null) _put(bookmark);
        return historyChanged;
    }
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
