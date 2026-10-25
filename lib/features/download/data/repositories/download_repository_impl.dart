import 'dart:async';
import 'dart:collection';

import 'package:bacakomik_app/core/data/models/comic_details_model.dart';
import 'package:bacakomik_app/core/domain/entities/comic_details.dart';
import 'package:bacakomik_app/core/error/failures.dart';
import 'package:bacakomik_app/core/storage/local_call.dart';
import 'package:bacakomik_app/core/utils/clock.dart';
import 'package:bacakomik_app/features/download/data/datasources/download_file_data_source.dart';
import 'package:bacakomik_app/features/download/data/datasources/download_local_data_source.dart';
import 'package:bacakomik_app/features/download/data/datasources/page_download_queue.dart';
import 'package:bacakomik_app/features/download/data/models/downloaded_chapter_model.dart';
import 'package:bacakomik_app/features/download/domain/entities/download_library.dart';
import 'package:bacakomik_app/features/download/domain/entities/downloaded_chapter.dart';
import 'package:bacakomik_app/features/download/domain/repositories/download_repository.dart';
import 'package:bacakomik_app/features/reader/domain/entities/chapter_content.dart';
import 'package:bacakomik_app/features/reader/domain/repositories/reader_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

/// Stores downloads. A queued chapter gets its page list here (one chapter
/// at a time, needs a connection), then its pages go to [PageDownloadQueue],
/// which keeps downloading in the background. Progress comes from page
/// events while the app runs and from the files on disk after that.
@LazySingleton(as: DownloadRepository)
class DownloadRepositoryImpl implements DownloadRepository {
  DownloadRepositoryImpl(
    this._local,
    this._files,
    this._pages,
    this._reader,
    this._clock,
  ) {
    _pages.events.listen((event) => _serial(() => _onPage(event)));
  }

  final DownloadLocalDataSource _local;
  final DownloadFileDataSource _files;
  final PageDownloadQueue _pages;
  final ReaderRepository _reader;
  final Clock _clock;

  final _changes = StreamController<void>.broadcast();

  /// Queued chapters waiting for their page list, in order.
  final _toPrepare = ListQueue<String>();
  Future<void>? _preparing;
  Future<void>? _restored;

  /// Record updates from page events and disk checks run one at a time, so
  /// two of them never overwrite each other's progress.
  Future<void> _lastUpdate = Future.value();

  @override
  Stream<void> get changes => _changes.stream;

  @override
  Future<Either<Failure, DownloadLibrary>> getDownloads() => runLocal(() async {
    await _restore();
    return DownloadLibrary(
      chapters: {
        for (final chapter in _local.getChapters())
          chapter.slug: chapter.toEntity(),
      },
      comics: {
        for (final comic in _local.getComics().values)
          comic.slug: DownloadedComic(
            slug: comic.slug,
            comicDetails: comic.comicDetails.toEntity(),
            coverPath: switch (comic.cover) {
              final cover? => await _files.absolute(cover),
              null => null,
            },
          ),
      },
    );
  });

  @override
  Future<Either<Failure, Unit>> enqueue({
    required String comicSlug,
    required ComicDetails comicDetails,
    required List<Chapter> chapters,
  }) => runLocal(() async {
    await _restore();
    await _pages.requestNotificationPermission();
    await _local.putComic(
      DownloadComicModel(
        slug: comicSlug,
        comicDetails: ComicDetailsModel.fromEntity(comicDetails),
        cover: _local.getComic(comicSlug)?.cover,
      ),
    );
    final now = _clock.now();
    final queued = <DownloadedChapterModel>[];
    for (final (index, chapter) in chapters.indexed) {
      final existing = _local.getChapter(chapter.slug);
      if (existing != null && existing.status != DownloadStatus.failed) {
        continue;
      }
      final model =
          existing ??
          DownloadedChapterModel(
            slug: chapter.slug,
            comicSlug: comicSlug,
            chapterNumber: chapter.number,
            // Keeps the given order when sorted by time.
            addedAt: now.add(Duration(milliseconds: index)),
          );
      queued.add(model.copyWith(status: DownloadStatus.queued));
    }
    await _queueAll(queued);
    return unit;
  });

  @override
  Future<Either<Failure, Unit>> retry(List<String> slugs) => runLocal(() async {
    await _queueAll([
      for (final slug in slugs)
        if (_local.getChapter(slug) case final chapter?
            when chapter.status == DownloadStatus.failed)
          chapter.copyWith(status: DownloadStatus.queued),
    ]);
    return unit;
  });

  @override
  Future<Either<Failure, Unit>> delete(List<String> slugs) =>
      runLocal(() async {
        final targets = slugs.toSet();
        _toPrepare.removeWhere(targets.contains);
        for (final slug in targets) {
          final chapter = _local.getChapter(slug);
          if (chapter == null) continue;
          if (chapter.status == DownloadStatus.downloading) {
            await _pages.cancel(slug);
          }
          await _files.delete(
            _files.chapterDir(chapter.comicSlug, chapter.chapterNumber),
          );
        }
        await _local.deleteChapters(targets.toList());
        await _pruneComics();
        _notify();
        return unit;
      });

  @override
  Future<Either<Failure, Unit>> clear() => runLocal(() async {
    _toPrepare.clear();
    await _pages.cancelAll();
    await _files.deleteAll();
    await _local.clear();
    _notify();
    return unit;
  });

  @override
  Future<Either<Failure, Unit>> sync() => runLocal(() async {
    await _restore();
    await _serial(_checkDisk);
    return unit;
  });

  @override
  Future<ChapterContent?> getOfflineChapter(String slug) async {
    try {
      final chapter = _local.getChapter(slug);
      if (chapter == null ||
          chapter.status != DownloadStatus.completed ||
          chapter.pages.isEmpty) {
        return null;
      }
      final pages = [
        for (final page in chapter.pages) await _files.absolute(page),
      ];
      // Files removed outside the app: read online instead.
      for (final page in chapter.pages) {
        if (!await _files.exists(page)) return null;
      }
      return ChapterContent(
        chapterTitle:
            chapter.chapterTitle ?? 'Chapter ${chapter.chapterNumber}',
        chapterNumber: chapter.chapterNumber,
        seriesSlug: chapter.comicSlug,
        previousChapterSlug: chapter.previousChapterSlug,
        nextChapterSlug: chapter.nextChapterSlug,
        images: pages,
        isOffline: true,
      );
    } catch (e) {
      debugPrint('Offline chapter $slug unreadable: $e');
      return null;
    }
  }

  @override
  Future<ComicDetails?> getOfflineComic(String comicSlug) async {
    try {
      return _local.getComic(comicSlug)?.comicDetails.toEntity();
    } catch (e) {
      debugPrint('Offline comic $comicSlug unreadable: $e');
      return null;
    }
  }

  /// Once per app run: picks up the background queue, catches up with
  /// pages saved while the app was closed, and prepares chapters that were
  /// still waiting for their page list.
  Future<void> _restore() => _restored ??= () async {
    await _pages.start();
    await _serial(_checkDisk);
    final waiting = [
      for (final chapter in _local.getChapters())
        if (chapter.status == DownloadStatus.queued) chapter,
    ]..sort((a, b) => a.addedAt.compareTo(b.addedAt));
    _toPrepare.addAll(waiting.map((c) => c.slug));
    _startPreparing();
  }();

  Future<void> _queueAll(List<DownloadedChapterModel> chapters) async {
    if (chapters.isEmpty) return;
    await _local.putChapters(chapters);
    _toPrepare.addAll(chapters.map((c) => c.slug));
    _notify();
    _startPreparing();
  }

  void _startPreparing() {
    if (_toPrepare.isEmpty) return;
    _preparing ??=
        () async {
          while (_toPrepare.isNotEmpty) {
            await _prepare(_toPrepare.removeFirst());
          }
        }().whenComplete(() {
          _preparing = null;
          // Queued while the last chapter was finishing.
          _startPreparing();
        });
  }

  /// Fetches the chapter's page list and hands the missing pages to the
  /// background queue.
  Future<void> _prepare(String slug) async {
    final queued = _local.getChapter(slug);
    if (queued == null || queued.status != DownloadStatus.queued) return;
    try {
      // Fresh page URLs, in case the source changed or they expire.
      final content = (await _reader.getChapter(slug))
          .getOrElse((failure) => throw failure);
      await _saveCover(queued.comicSlug);

      final dir = _files.chapterDir(queued.comicSlug, queued.chapterNumber);
      final images = content.images;
      final planned = [
        for (var i = 0; i < images.length; i++)
          _files.pagePath(dir, i, images[i]),
      ];
      final saved = <String>[];
      final missing = <PageJob>[];
      var size = 0;
      for (var i = 0; i < planned.length; i++) {
        if (await _files.exists(planned[i])) {
          saved.add(planned[i]);
          size += await _files.size(planned[i]);
        } else {
          missing.add(
            PageJob(
              chapterSlug: slug,
              index: i,
              url: images[i],
              path: planned[i],
              headers: content.imageHeaders,
            ),
          );
        }
      }
      final chapter = queued.copyWith(
        status: missing.isEmpty
            ? DownloadStatus.completed
            : DownloadStatus.downloading,
        chapterTitle: content.chapterTitle,
        previousChapterSlug: content.previousChapterSlug,
        nextChapterSlug: content.nextChapterSlug,
        pageCount: images.length,
        planned: planned,
        pages: saved,
        sizeBytes: size,
        downloadedAt: missing.isEmpty ? _clock.now() : null,
      );
      // Deleted while the page list was loading.
      if (!await _save(chapter)) return;
      await _pages.enqueue(missing);
    } catch (e) {
      debugPrint('Download $slug failed: $e');
      if (_local.getChapter(slug) case final latest?) {
        await _save(latest.copyWith(status: DownloadStatus.failed));
      }
    }
  }

  Future<void> _onPage(PageEvent event) async {
    final chapter = _local.getChapter(event.chapterSlug);
    if (chapter == null || chapter.status != DownloadStatus.downloading) {
      return;
    }
    if (event.result == PageResult.failed) {
      // Saved pages stay; a retry fetches the rest.
      await _pages.cancel(chapter.slug);
      await _save(chapter.copyWith(status: DownloadStatus.failed));
      return;
    }
    if (event.index >= chapter.planned.length) return;
    final path = chapter.planned[event.index];
    if (chapter.pages.contains(path)) return;
    final saved = {...chapter.pages, path};
    await _save(
      _withPages(chapter, saved, chapter.sizeBytes + await _files.size(path)),
    );
  }

  /// Brings downloading chapters up to date with the files on disk: pages
  /// saved while the app was suspended or closed. A chapter with nothing
  /// left in the background queue and pages missing has failed.
  Future<void> _checkDisk() async {
    final downloading = [
      for (final chapter in _local.getChapters())
        if (chapter.status == DownloadStatus.downloading) chapter,
    ];
    if (downloading.isEmpty) return;
    final active = await _pages.activeChapters();
    for (final chapter in downloading) {
      final saved = <String>{};
      var size = 0;
      for (final path in chapter.planned) {
        if (await _files.exists(path)) {
          saved.add(path);
          size += await _files.size(path);
        }
      }
      var updated = _withPages(chapter, saved, size);
      if (!updated.status.isCompleted && !active.contains(chapter.slug)) {
        updated = updated.copyWith(status: DownloadStatus.failed);
      }
      await _save(updated);
    }
  }

  /// [chapter] with [saved] pages in page order; completed once every page
  /// is saved.
  DownloadedChapterModel _withPages(
    DownloadedChapterModel chapter,
    Set<String> saved,
    int size,
  ) {
    final pages = [
      for (final path in chapter.planned)
        if (saved.contains(path)) path,
    ];
    final done = pages.length == chapter.pageCount && chapter.pageCount > 0;
    return chapter.copyWith(
      pages: pages,
      sizeBytes: size,
      status: done ? DownloadStatus.completed : null,
      downloadedAt: done ? _clock.now() : null,
    );
  }

  /// Saves the comic's cover once. A missing cover does not fail the
  /// chapter.
  Future<void> _saveCover(String comicSlug) async {
    final comic = _local.getComic(comicSlug);
    if (comic == null) return;
    if (comic.cover case final cover? when await _files.exists(cover)) return;
    try {
      final file = await _files.download(
        comic.comicDetails.coverImg,
        '${_files.comicDir(comicSlug)}/cover',
      );
      await _local.putComic(
        DownloadComicModel(
          slug: comic.slug,
          comicDetails: comic.comicDetails,
          cover: file.path,
        ),
      );
    } catch (e) {
      debugPrint('Cover of $comicSlug not saved: $e');
    }
  }

  /// Drops comics without any download, with their folder.
  Future<void> _pruneComics() async {
    final used = {for (final c in _local.getChapters()) c.comicSlug};
    final unused = [
      for (final slug in _local.getComics().keys)
        if (!used.contains(slug)) slug,
    ];
    for (final slug in unused) {
      await _files.delete(_files.comicDir(slug));
    }
    if (unused.isNotEmpty) await _local.deleteComics(unused);
  }

  /// False when the chapter was deleted meanwhile; nothing is written then.
  Future<bool> _save(DownloadedChapterModel chapter) async {
    if (_local.getChapter(chapter.slug) == null) return false;
    await _local.putChapters([chapter]);
    _notify();
    return true;
  }

  Future<void> _serial(Future<void> Function() update) {
    final next = _lastUpdate.then((_) => update()).catchError((Object e) {
      debugPrint('Download update failed: $e');
    });
    return _lastUpdate = next;
  }

  void _notify() => _changes.add(null);
}

extension on DownloadStatus {
  bool get isCompleted => this == DownloadStatus.completed;
}
