import 'dart:async';

import 'package:bacakomik_app/core/domain/entities/comic_details.dart';
import 'package:bacakomik_app/core/error/failures.dart';
import 'package:bacakomik_app/core/usecase/usecase.dart';
import 'package:bacakomik_app/features/download/domain/entities/download_library.dart';
import 'package:bacakomik_app/features/download/domain/usecases/download_usecases.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

/// Downloaded and queued chapters. Reloads whenever storage changes, so
/// download progress shows as it happens.
@injectable
class DownloadCubit extends Cubit<DownloadLibrary> {
  DownloadCubit(
    this._getDownloads,
    WatchDownloads watchDownloads,
    this._enqueue,
    this._retry,
    this._delete,
    this._clear,
  ) : super(const DownloadLibrary()) {
    _changes = watchDownloads().listen((_) => load());
  }

  final GetDownloads _getDownloads;
  final EnqueueDownloads _enqueue;
  final RetryDownloads _retry;
  final DeleteDownloads _delete;
  final ClearDownloads _clear;
  late final StreamSubscription<void> _changes;

  /// Page progress fires many changes; one reload at a time, plus one more
  /// if something changed meanwhile.
  Future<void>? _loading;
  var _reloadAgain = false;

  Future<void> load() {
    if (_loading != null) {
      _reloadAgain = true;
      return _loading!;
    }
    return _loading = _load().whenComplete(() {
      _loading = null;
      if (_reloadAgain) {
        _reloadAgain = false;
        load();
      }
    });
  }

  Future<void> _load() async {
    final result = await _getDownloads(const NoParams());
    if (isClosed) return;
    result.fold(_log, emit);
  }

  /// Queues [chapters] in the given order.
  Future<void> download({
    required String comicSlug,
    required ComicDetails comicDetails,
    required List<Chapter> chapters,
  }) async {
    final result = await _enqueue(
      EnqueueParams(
        comicSlug: comicSlug,
        comicDetails: comicDetails,
        chapters: chapters,
      ),
    );
    result.fold(_log, (_) {});
  }

  Future<void> retry(List<String> slugs) async =>
      (await _retry([...slugs])).fold(_log, (_) {});

  /// Cancels queued chapters and deletes downloaded ones.
  Future<void> delete(List<String> slugs) async =>
      (await _delete([...slugs])).fold(_log, (_) {});

  Future<void> deleteComic(String comicSlug) => delete([
    for (final chapter in state.chapters.values)
      if (chapter.comicSlug == comicSlug) chapter.slug,
  ]);

  Future<void> clear() async =>
      (await _clear(const NoParams())).fold(_log, (_) {});

  @override
  Future<void> close() async {
    await _changes.cancel();
    return super.close();
  }

  void _log(Failure failure) => debugPrint('DownloadCubit: $failure');
}
