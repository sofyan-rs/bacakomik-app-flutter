import 'dart:async';
import 'dart:io';

import 'package:background_downloader/background_downloader.dart';
import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:bacakomik_app/core/network/image_cache.dart';
import 'package:bacakomik_app/features/download/data/datasources/download_file_data_source.dart';
import 'package:injectable/injectable.dart';

/// One chapter page to save.
class PageJob {
  const PageJob({
    required this.chapterSlug,
    required this.index,
    required this.url,
    required this.path,
    this.headers = const {},
  });

  final String chapterSlug;

  /// Sent with the request, e.g. a Referer the image host requires.
  final Map<String, String> headers;

  /// 0-based page index.
  final int index;
  final String url;

  /// Where the page goes, relative to the downloads folder.
  final String path;
}

enum PageResult { saved, failed }

/// A page that finished, successfully or not.
class PageEvent {
  const PageEvent(this.chapterSlug, this.index, this.result);

  final String chapterSlug;
  final int index;
  final PageResult result;
}

/// Downloads pages outside the Dart isolate, so they keep going while the
/// app is in the background, the phone is locked or the app was closed.
/// A notification shows progress.
abstract interface class PageDownloadQueue {
  /// Finished pages. Only delivered while the app runs; pages finished in
  /// the meantime are found on disk.
  Stream<PageEvent> get events;

  /// Picks up work and updates from earlier app runs. Call once, early.
  Future<void> start();

  /// Asks for the notification permission when it was never asked.
  Future<void> requestNotificationPermission();

  /// Runs after jobs that were enqueued before them.
  Future<void> enqueue(List<PageJob> jobs);

  /// Chapters that still have pages waiting or downloading.
  Future<Set<String>> activeChapters();

  Future<void> cancel(String chapterSlug);

  Future<void> cancelAll();
}

@LazySingleton(as: PageDownloadQueue)
class BackgroundPageDownloadQueue implements PageDownloadQueue {
  BackgroundPageDownloadQueue(this._files) {
    // Listening has to start before FileDownloader.start(), which replays
    // updates from while the app was suspended.
    _downloader.updates.listen(_onUpdate);
  }

  static const _group = 'chapter_pages';
  static const _maxConcurrent = 3;

  final DownloadFileDataSource _files;
  final _downloader = FileDownloader();
  final _events = StreamController<PageEvent>.broadcast();
  Future<void>? _started;

  @override
  Stream<PageEvent> get events => _events.stream;

  @override
  Future<void> start() => _started ??= () async {
    // Native-side queue: pages start in the order they were enqueued, a few
    // at a time, even while the app is suspended.
    await _downloader.configure(
      globalConfig: (Config.holdingQueue, (_maxConcurrent, null, null)),
    );
    _downloader.configureNotificationForGroup(
      _group,
      running: const TaskNotification(
        AppText.downloadNotificationRunning,
        '{numFinished}/{numTotal} ${AppText.pages}',
      ),
      complete: const TaskNotification(
        AppText.downloadNotificationDone,
        '{numTotal} ${AppText.pages}',
      ),
      error: const TaskNotification(
        AppText.downloadNotificationFailed,
        '{numFailed}/{numTotal} ${AppText.pages}',
      ),
      progressBar: true,
      groupNotificationId: _group,
    );
    await _downloader.start(autoCleanDatabase: true);
  }();

  @override
  Future<void> requestNotificationPermission() async {
    const type = PermissionType.notifications;
    final status = await _downloader.permissions.status(type);
    if (status != PermissionStatus.granted) {
      await _downloader.permissions.request(type);
    }
  }

  @override
  Future<void> enqueue(List<PageJob> jobs) async {
    if (jobs.isEmpty) return;
    await start();
    final root = await _files.root;
    for (final job in jobs) {
      if (_blockingHosts.contains(Uri.parse(job.url).host)) {
        unawaited(
          _downloadInApp(
            job.chapterSlug,
            job.index,
            job.url,
            job.headers,
            '$root/${job.path}',
          ),
        );
      }
    }
    final native = [
      for (final job in jobs)
        if (!_blockingHosts.contains(Uri.parse(job.url).host)) job,
    ];
    final now = DateTime.now();
    await _downloader.enqueueAll([
      for (final (i, job) in native.indexed)
        DownloadTask(
          taskId: _taskId(job.chapterSlug, job.index),
          url: job.url,
          headers: job.headers,
          baseDirectory: BaseDirectory.root,
          directory: '$root/${_dirOf(job.path)}',
          filename: job.path.split('/').last,
          group: _group,
          metaData: job.chapterSlug,
          // Exponential backoff rides out short connection drops.
          retries: 10,
          // Keeps the given order in the holding queue.
          creationTime: now.add(Duration(milliseconds: i)),
        ),
    ]);
  }

  @override
  Future<Set<String>> activeChapters() async {
    await start();
    final tasks = await _downloader.allTasks(group: _group);
    return {for (final task in tasks) task.metaData, ..._inApp.keys};
  }

  @override
  Future<void> cancel(String chapterSlug) async {
    _inApp.remove(chapterSlug);
    final tasks = await _downloader.allTasks(group: _group);
    await _downloader.cancelTasksWithIds([
      for (final task in tasks)
        if (task.metaData == chapterSlug) task.taskId,
    ]);
  }

  @override
  Future<void> cancelAll() {
    _inApp.clear();
    return _downloader.cancelAll(group: _group);
  }

  void _onUpdate(TaskUpdate update) {
    if (update is! TaskStatusUpdate || update.task.group != _group) return;
    final index = _indexOf(update.task.taskId);
    if (index == null) return;
    if (update.status == TaskStatus.waitingToRetry) {
      unawaited(_onRetry(update.task, index));
      return;
    }
    final result = switch (update.status) {
      TaskStatus.complete => PageResult.saved,
      TaskStatus.failed || TaskStatus.notFound => PageResult.failed,
      _ => null,
    };
    if (result == null) return;
    _events.add(PageEvent(update.task.metaData, index, result));
  }

  /// Image hosts that turn the native downloader away the way Cloudflare
  /// does (WestManga's chapter pages); retrying would not help. Their pages
  /// are saved through the app's image cache, which fetches from inside the
  /// site when it has to. That runs only while the app does.
  final _blockingHosts = <String>{};

  /// Hosts being checked, so each is checked once at a time.
  final _checking = <String, Future<bool>>{};

  /// Pages being saved in the app, per chapter.
  final _inApp = <String, int>{};

  /// A page failed and waits to be retried, which the update does not say
  /// why: checks once whether its host blocks the native downloader.
  Future<void> _onRetry(Task task, int index) async {
    final host = Uri.parse(task.url).host;
    if (!_blockingHosts.contains(host)) {
      final blocks = await (_checking[host] ??=
          imageHostBlocks(task.url, headers: task.headers).whenComplete(() {
            // Not `=>`: the removed future is this one, which would wait on
            // itself.
            _checking.remove(host);
          }));
      if (!blocks) return;
      _blockingHosts.add(host);
    }
    await _downloader.cancelTaskWithId(task.taskId);
    await _downloadInApp(
      task.metaData,
      index,
      task.url,
      task.headers,
      await task.filePath(),
    );
  }

  Future<void> _downloadInApp(
    String chapterSlug,
    int index,
    String url,
    Map<String, String> headers,
    String path,
  ) async {
    _inApp.update(chapterSlug, (n) => n + 1, ifAbsent: () => 1);
    var result = PageResult.failed;
    try {
      final cached = await comicImageCache.getSingleFile(url, headers: headers);
      // Cancelled meanwhile.
      if (!_inApp.containsKey(chapterSlug)) return;
      final target = File(path);
      await target.parent.create(recursive: true);
      await cached.copy(target.path);
      result = PageResult.saved;
    } catch (_) {
      // Reported as a failed page.
    }
    final left = (_inApp[chapterSlug] ?? 0) - 1;
    if (left > 0) {
      _inApp[chapterSlug] = left;
    } else if (_inApp.remove(chapterSlug) == null) {
      return;
    }
    _events.add(PageEvent(chapterSlug, index, result));
  }

  static String _taskId(String chapterSlug, int index) => '$chapterSlug#$index';

  static int? _indexOf(String taskId) =>
      int.tryParse(taskId.substring(taskId.lastIndexOf('#') + 1));

  static String _dirOf(String path) => path.substring(0, path.lastIndexOf('/'));
}
