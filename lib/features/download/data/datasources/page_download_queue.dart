import 'dart:async';

import 'package:background_downloader/background_downloader.dart';
import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:bacakomik_app/features/download/data/datasources/download_file_data_source.dart';
import 'package:injectable/injectable.dart';

/// One chapter page to save.
class PageJob {
  const PageJob({
    required this.chapterSlug,
    required this.index,
    required this.url,
    required this.path,
  });

  final String chapterSlug;

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
    final now = DateTime.now();
    await _downloader.enqueueAll([
      for (final (i, job) in jobs.indexed)
        DownloadTask(
          taskId: _taskId(job.chapterSlug, job.index),
          url: job.url,
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
    return {for (final task in tasks) task.metaData};
  }

  @override
  Future<void> cancel(String chapterSlug) async {
    final tasks = await _downloader.allTasks(group: _group);
    await _downloader.cancelTasksWithIds([
      for (final task in tasks)
        if (task.metaData == chapterSlug) task.taskId,
    ]);
  }

  @override
  Future<void> cancelAll() => _downloader.cancelAll(group: _group);

  void _onUpdate(TaskUpdate update) {
    if (update is! TaskStatusUpdate || update.task.group != _group) return;
    final result = switch (update.status) {
      TaskStatus.complete => PageResult.saved,
      TaskStatus.failed || TaskStatus.notFound => PageResult.failed,
      _ => null,
    };
    final index = _indexOf(update.task.taskId);
    if (result == null || index == null) return;
    _events.add(PageEvent(update.task.metaData, index, result));
  }

  static String _taskId(String chapterSlug, int index) => '$chapterSlug#$index';

  static int? _indexOf(String taskId) =>
      int.tryParse(taskId.substring(taskId.lastIndexOf('#') + 1));

  static String _dirOf(String path) => path.substring(0, path.lastIndexOf('/'));
}
