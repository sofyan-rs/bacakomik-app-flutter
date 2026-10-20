import 'dart:async';
import 'dart:collection';

import 'package:bacakomik_app/core/data/models/comic_details_model.dart';
import 'package:bacakomik_app/core/domain/entities/comic_details.dart';
import 'package:bacakomik_app/core/error/failures.dart';
import 'package:bacakomik_app/core/storage/local_call.dart';
import 'package:bacakomik_app/core/utils/clock.dart';
import 'package:bacakomik_app/features/download/data/datasources/download_file_data_source.dart';
import 'package:bacakomik_app/features/download/data/datasources/download_local_data_source.dart';
import 'package:bacakomik_app/features/download/data/models/downloaded_chapter_model.dart';
import 'package:bacakomik_app/features/download/domain/entities/download_library.dart';
import 'package:bacakomik_app/features/download/domain/entities/downloaded_chapter.dart';
import 'package:bacakomik_app/features/download/domain/repositories/download_repository.dart';
import 'package:bacakomik_app/features/reader/domain/entities/chapter_content.dart';
import 'package:bacakomik_app/features/reader/domain/repositories/reader_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

/// Stores downloads and runs the queue: one chapter at a time, a few pages
/// of it in parallel. Progress is written to storage after every page, and
/// [changes] tells listeners to reload.
@LazySingleton(as: DownloadRepository)
class DownloadRepositoryImpl implements DownloadRepository {
  DownloadRepositoryImpl(this._local, this._files, this._reader, this._clock);

  static const _parallelPages = 3;
  static const _pageAttempts = 3;

  final DownloadLocalDataSource _local;
  final DownloadFileDataSource _files;
  final ReaderRepository _reader;
  final Clock _clock;

  final _changes = StreamController<void>.broadcast();
  final _queue = ListQueue<String>();
  var _restored = false;
  Future<void>? _worker;
  String? _activeSlug;
  CancelToken? _activeToken;
  Future<void>? _activeJob;

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
        _queue.removeWhere(targets.contains);
        if (targets.contains(_activeSlug)) await _cancelActive();
        for (final slug in targets) {
          if (_local.getChapter(slug) case final chapter?) {
            await _files.delete(
              _files.chapterDir(chapter.comicSlug, chapter.chapterNumber),
            );
          }
        }
        await _local.deleteChapters(targets.toList());
        await _pruneComics();
        _notify();
        return unit;
      });

  @override
  Future<Either<Failure, Unit>> clear() => runLocal(() async {
    _queue.clear();
    await _cancelActive();
    await _files.deleteAll();
    await _local.clear();
    _notify();
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

  /// Downloads cut off by the app closing cannot resume on their own; they
  /// become failed once per app run so the user can retry them.
  Future<void> _restore() async {
    if (_restored) return;
    _restored = true;
    await _local.putChapters([
      for (final chapter in _local.getChapters())
        if (chapter.status == DownloadStatus.queued ||
            chapter.status == DownloadStatus.downloading)
          chapter.copyWith(status: DownloadStatus.failed),
    ]);
  }

  Future<void> _queueAll(List<DownloadedChapterModel> chapters) async {
    if (chapters.isEmpty) return;
    await _local.putChapters(chapters);
    _queue.addAll(chapters.map((c) => c.slug));
    _notify();
    _start();
  }

  void _start() {
    _worker ??= _drain().whenComplete(() {
      _worker = null;
      // Queued while the last job was finishing.
      if (_queue.isNotEmpty) _start();
    });
  }

  Future<void> _drain() async {
    while (_queue.isNotEmpty) {
      final job = _download(_queue.removeFirst());
      _activeJob = job;
      await job;
    }
  }

  Future<void> _cancelActive() async {
    _activeToken?.cancel();
    await _activeJob;
  }

  Future<void> _download(String slug) async {
    final queued = _local.getChapter(slug);
    if (queued == null || queued.status != DownloadStatus.queued) return;
    final token = CancelToken();
    _activeSlug = slug;
    _activeToken = token;
    try {
      var chapter = queued.copyWith(status: DownloadStatus.downloading);
      await _save(chapter);

      // Fresh page URLs, in case the source changed or they expire.
      final content = (await _reader.getChapter(slug))
          .getOrElse((failure) => throw failure);
      if (token.isCancelled) return;
      await _saveCover(chapter.comicSlug, token);

      final images = content.images;
      final saved = <int, String>{
        // The page count changed: the saved pages may be different ones.
        if (chapter.pageCount == 0 || chapter.pageCount == images.length)
          for (final path in chapter.pages) ?_pageIndex(path): path,
      };
      chapter = chapter.copyWith(
        chapterTitle: content.chapterTitle,
        previousChapterSlug: content.previousChapterSlug,
        nextChapterSlug: content.nextChapterSlug,
        pageCount: images.length,
        pages: _inOrder(saved),
        sizeBytes: saved.isEmpty ? 0 : chapter.sizeBytes,
      );
      await _save(chapter);

      final dir = _files.chapterDir(chapter.comicSlug, chapter.chapterNumber);
      final pending = [
        for (var i = 0; i < images.length; i++)
          if (!saved.containsKey(i)) i,
      ];
      var next = 0;
      Object? error;
      Future<void> worker() async {
        while (error == null && !token.isCancelled && next < pending.length) {
          final index = pending[next++];
          try {
            final file = await _downloadPage(
              images[index],
              '$dir/${index.toString().padLeft(3, '0')}',
              token,
            );
            if (token.isCancelled) return;
            saved[index] = file.path;
            chapter = chapter.copyWith(
              pages: _inOrder(saved),
              sizeBytes: chapter.sizeBytes + file.size,
            );
            await _save(chapter);
          } catch (e) {
            if (!token.isCancelled) error ??= e;
          }
        }
      }

      await Future.wait([for (var i = 0; i < _parallelPages; i++) worker()]);
      if (token.isCancelled) return;
      if (error case final error?) throw error;
      await _save(
        chapter.copyWith(
          status: DownloadStatus.completed,
          downloadedAt: _clock.now(),
        ),
      );
    } catch (e) {
      if (token.isCancelled) return;
      debugPrint('Download $slug failed: $e');
      if (_local.getChapter(slug) case final latest?) {
        await _save(latest.copyWith(status: DownloadStatus.failed));
      }
    } finally {
      _activeSlug = null;
      _activeToken = null;
    }
  }

  Future<({String path, int size})> _downloadPage(
    String url,
    String pathWithoutExtension,
    CancelToken token,
  ) async {
    for (var attempt = 1; ; attempt++) {
      try {
        return await _files.download(
          url,
          pathWithoutExtension,
          cancelToken: token,
        );
      } catch (_) {
        if (token.isCancelled || attempt >= _pageAttempts) rethrow;
        await Future<void>.delayed(Duration(seconds: attempt));
      }
    }
  }

  /// Saves the comic's cover once. A missing cover does not fail the
  /// chapter.
  Future<void> _saveCover(String comicSlug, CancelToken token) async {
    final comic = _local.getComic(comicSlug);
    if (comic == null) return;
    if (comic.cover case final cover? when await _files.exists(cover)) return;
    try {
      final file = await _files.download(
        comic.comicDetails.coverImg,
        '${_files.comicDir(comicSlug)}/cover',
        cancelToken: token,
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

  Future<void> _save(DownloadedChapterModel chapter) async {
    // Deleted while the page was downloading.
    if (_local.getChapter(chapter.slug) == null) return;
    await _local.putChapters([chapter]);
    _notify();
  }

  void _notify() => _changes.add(null);

  static List<String> _inOrder(Map<int, String> pages) => [
    for (final index in pages.keys.toList()..sort()) pages[index]!,
  ];

  /// `"comic/12/007.webp"` → 7.
  static int? _pageIndex(String path) {
    final name = path.split('/').last;
    return int.tryParse(name.split('.').first);
  }
}
