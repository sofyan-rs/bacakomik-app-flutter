import 'dart:async';

import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:bacakomik_app/core/error/failures.dart';
import 'package:bacakomik_app/core/notifications/progress_notifier.dart';
import 'package:bacakomik_app/core/source/comic_key.dart';
import 'package:bacakomik_app/features/bookmark/domain/usecases/refresh_bookmark.dart';
import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';

typedef RefreshCall = Future<Either<Failure, RefreshResult>> Function(
  String key,
  RefreshCancelToken token,
);

/// Checks bookmarks for new chapters, by key: up to [maxParallel] at once
/// and at most one per source ([ComicKey.sourceOf]), since a site may block
/// a burst of requests. Shows `done / total` in a notification while it
/// runs, then how many comics changed.
///
/// [add] while running joins the run; [cancel] stops it; [drop] forgets
/// keys whose bookmark is gone. A comic abandoned by [cancel], [drop] or
/// [timeout] has its token cancelled, so it writes nothing more; a result
/// that still arrives (its write had begun) goes to [onResult] with
/// `late: true`, so the screen shows what was saved.
class BookmarkRefreshQueue {
  BookmarkRefreshQueue({
    required this.refresh,
    required this.notifier,
    required this.onResult,
    this.maxParallel = 3,
    this.timeout = const Duration(seconds: 90),
  });

  /// Checks one comic; its writes must stop once the token is cancelled.
  final RefreshCall refresh;
  final ProgressNotifier notifier;

  /// Called for each comic checked. Not called after [dispose].
  final void Function(String key, RefreshResult result, {required bool late})
  onResult;

  final int maxParallel;

  /// A comic that takes longer is skipped, so one stuck site cannot hold
  /// up the rest.
  final Duration timeout;

  /// Whether a run is going; Bookmarks shows a stop button.
  final refreshing = ValueNotifier<bool>(false);

  /// Keys waiting, in order.
  final _queue = <String>[];

  /// Keys queued or checked in the current run, so none is checked twice.
  final _seen = <String>{};

  /// Comics being checked, by key.
  final _running = <String, _Job>{};
  final _busySources = <String>{};

  var _done = 0;
  var _updated = 0;
  var _cancelled = false;
  var _disposed = false;
  (int, int)? _reported;
  Future<void>? _run;
  Completer<void>? _wake;

  /// Whether a run is going.
  bool get running => _run != null;

  /// Keys queued or being checked.
  @visibleForTesting
  Iterable<String> get pending => [..._running.keys, ..._queue];

  /// Queues [keys] not checked yet in this run. Completes when the run
  /// (including comics added meanwhile) is over.
  Future<void> add(Iterable<String> keys) {
    for (final key in keys) {
      if (_seen.add(key)) _queue.add(key);
    }
    _wakeUp();
    if (_run == null) refreshing.value = true;
    return _run ??= _drain().whenComplete(() {
      _run = null;
      if (!_disposed) refreshing.value = false;
    });
  }

  /// Stops the run: comics being checked are abandoned and the queue
  /// dropped. Comics checked so far keep their updates.
  void cancel() {
    _queue.clear();
    if (_run == null) return;
    _cancelled = true;
    for (final job in _running.values) {
      job.abandon();
    }
    _wakeUp();
  }

  /// Forgets the keys for which [gone] is true: queued ones are dropped,
  /// running ones abandoned. For bookmarks deleted, migrated or synced
  /// away while queued.
  void drop(bool Function(String key) gone) {
    if (_run == null) return;
    _queue.removeWhere(gone);
    _seen.removeWhere(gone);
    for (final MapEntry(:key, value: job) in _running.entries) {
      if (gone(key)) job.abandon();
    }
    _wakeUp();
  }

  void dispose() {
    _disposed = true;
    cancel();
    refreshing.dispose();
  }

  void _wakeUp() {
    if (!(_wake?.isCompleted ?? true)) _wake!.complete();
  }

  Future<void> _drain() async {
    const id = ProgressIds.bookmarkRefresh;
    // Comics added while a run was ending, or after it was stopped, get a
    // run of their own instead of waiting in the queue for the next pull.
    do {
      _cancelled = false;
      _done = 0;
      _updated = 0;
      _reported = null;
      _seen
        ..clear()
        ..addAll(_queue);
      while (true) {
        if (!_cancelled) _startJobs();
        if (_running.isEmpty) break;
        _report();
        final wake = _wake = Completer<void>();
        await wake.future;
      }
      if (_disposed) return;
      await notifier.finish(
        id,
        title: _updated > 0 ? AppText.bookmarksUpdated : null,
        body:
            '${AppText.count(_updated, AppText.comic, AppText.comics)} '
            '${AppText.haveNewChapters}',
      );
    } while (_queue.isNotEmpty && !_disposed);
  }

  /// Starts queued comics, in order, while slots are free, skipping those
  /// whose source is busy.
  void _startJobs() {
    for (var i = 0; i < _queue.length && _running.length < maxParallel;) {
      final key = _queue[i];
      final source = ComicKey.sourceOf(key);
      if (_busySources.contains(source)) {
        i++;
        continue;
      }
      _queue.removeAt(i);
      final job = _running[key] = _Job();
      _busySources.add(source);
      unawaited(_check(key, source, job));
    }
  }

  void _report() {
    if (_cancelled) return;
    final progress = (_done, _done + _running.length + _queue.length);
    if (progress == _reported) return;
    _reported = progress;
    unawaited(
      notifier.progress(
        ProgressIds.bookmarkRefresh,
        title: AppText.updatingBookmarks,
        done: progress.$1,
        total: progress.$2,
        cancelable: true,
      ),
    );
  }

  Future<void> _check(String key, String source, _Job job) async {
    final work = Future.sync(() => refresh(key, job.token)).catchError(
      (Object e) => left<Failure, RefreshResult>(ServerFailure('$e')),
    );
    final result =
        await Future.any<Either<Failure, RefreshResult>?>([
          work,
          job.abandoned.future.then((_) => null),
        ]).timeout(
          timeout,
          onTimeout: () {
            debugPrint('BookmarkRefresh: $key timed out');
            return null;
          },
        );
    _running.remove(key);
    _busySources.remove(source);
    _done++;
    if (result == null) {
      // Abandoned: its writes are skipped from now on; one already begun
      // still lands, and is shown when it does.
      job.abandon();
      unawaited(
        work.then((late) {
          if (!_disposed) onResult(key, _unwrap(late), late: true);
        }),
      );
    } else if (!_disposed) {
      final unwrapped = _unwrap(result);
      if (unwrapped.saved != null) _updated++;
      onResult(key, unwrapped, late: false);
    }
    _wakeUp();
  }

  static RefreshResult _unwrap(Either<Failure, RefreshResult> result) =>
      result.getOrElse(
        (failure) => (saved: null, historyChanged: false, failure: failure),
      );
}

class _Job {
  final token = RefreshCancelToken();
  final abandoned = Completer<void>();

  void abandon() {
    token.cancel();
    if (!abandoned.isCompleted) abandoned.complete();
  }
}
