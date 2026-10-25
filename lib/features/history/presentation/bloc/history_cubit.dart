import 'package:bacakomik_app/core/domain/entities/comic_details.dart';
import 'package:bacakomik_app/core/error/failures.dart';
import 'package:bacakomik_app/core/usecase/usecase.dart';
import 'package:bacakomik_app/core/utils/clock.dart';
import 'package:bacakomik_app/features/history/domain/entities/read_history.dart';
import 'package:bacakomik_app/features/history/domain/usecases/history_usecases.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

/// Read chapters, newest first.
@injectable
class HistoryCubit extends Cubit<List<ReadHistory>> {
  HistoryCubit(
    this._getHistory,
    this._saveHistory,
    this._removeHistory,
    this._removeComicHistory,
    this._clearHistory,
    this._clock,
  ) : super(const []);

  final GetHistory _getHistory;
  final SaveHistory _saveHistory;
  final RemoveHistory _removeHistory;
  final RemoveComicHistory _removeComicHistory;
  final ClearHistory _clearHistory;
  final Clock _clock;

  Future<void> load() async {
    final result = await _getHistory(const NoParams());
    result.fold(_log, emit);
  }

  /// Records [page] (0-based) as the reading position of a chapter with
  /// [pageCount] pages. Reaching the last page finishes the chapter; a
  /// finished chapter stays finished when read again.
  Future<void> addHistory({
    required String slug,
    required String chapterNumber,
    required ComicDetails comicDetails,
    required String comicSlug,
    required int page,
    required int pageCount,
  }) {
    final finished =
        page >= pageCount - 1 || (index.chapter(slug)?.isFinished ?? false);
    return addHistoryList([
      ReadHistory(
        slug: slug,
        chapterNumber: chapterNumber,
        readDate: _clock.now(),
        comicDetails: comicDetails,
        comicSlug: comicSlug,
        page: finished ? null : page,
        pageCount: finished ? null : pageCount,
      ),
    ]);
  }

  Future<void> addHistoryList(List<ReadHistory> history) =>
      _thenReload(_saveHistory([...history]));

  /// Marks every chapter of each comic read, keyed by series slug. Finished
  /// chapters keep their entry; unread and half-read ones are finished. The
  /// newest chapter gets the newest read date, so it shows as the latest.
  Future<void> markAllRead(Map<String, ComicDetails> comics) {
    final now = _clock.now();
    return addHistoryList([
      for (final MapEntry(key: comicSlug, value: details) in comics.entries)
        for (final (i, chapter) in details.chapters.indexed)
          if (!index.isFinished(chapter.slug))
            ReadHistory(
              slug: chapter.slug,
              chapterNumber: chapter.number,
              // Chapters are newest first.
              readDate: now.subtract(Duration(milliseconds: i)),
              comicDetails: details,
              comicSlug: comicSlug,
            ),
    ]);
  }

  Future<void> removeHistory(String slug) => removeHistoryList([slug]);

  Future<void> removeHistoryList(List<String> slugs) =>
      _thenReload(_removeHistory([...slugs]));

  /// Removes every read chapter of one comic.
  Future<void> removeHistoryBySlug(String comicSlug) =>
      _thenReload(_removeComicHistory(comicSlug));

  /// Removes every read chapter of each comic, reloading once.
  Future<void> markAllUnread(Iterable<String> comicSlugs) async {
    for (final slug in comicSlugs) {
      (await _removeComicHistory(slug)).fold(_log, (_) {});
    }
    await load();
  }

  Future<void> clearHistory() => _thenReload(_clearHistory(const NoParams()));

  /// Lookups for the current state, rebuilt only when the state changes.
  HistoryIndex get index {
    if (!identical(_indexed, state)) {
      _indexed = state;
      _index = HistoryIndex(state);
    }
    return _index;
  }

  List<ReadHistory>? _indexed;
  late HistoryIndex _index;

  bool isInHistory(String slug) => index.containsChapter(slug);

  /// Where to reopen a chapter: the saved page while unfinished, else 0.
  int resumePage(String slug) => index.chapter(slug)?.page ?? 0;

  /// Only valid when [state] is not empty.
  ReadHistory get latestHistory => index.latest!;

  int getHistoryCountBySlug(String comicSlug) => index.countOf(comicSlug);

  ReadHistory? getLatestHistoryBySlug(String comicSlug) =>
      index.latestOf(comicSlug);

  List<ComicLatestHistory> get latestHistories => index.perComic;

  Future<void> _thenReload(Future<Either<Failure, Unit>> action) async {
    (await action).fold(_log, (_) {});
    await load();
  }

  void _log(Failure failure) => debugPrint('HistoryCubit: $failure');
}
