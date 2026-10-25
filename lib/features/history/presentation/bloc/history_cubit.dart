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

/// Read chapters, newest first ([ReadHistoryQueries.newestFirst]).
///
/// Edits made through the cubit update the list in memory to what [load]
/// would read back, instead of rereading the whole history; a failed edit
/// reloads. Call [load] after the history changed elsewhere (sync, import,
/// restore, migration).
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

  /// Counts in-memory edits, so a [load] that read the boxes before an edit
  /// landed reads again instead of dropping it.
  var _edits = 0;

  Future<void> load() async {
    while (true) {
      final edits = _edits;
      final result = await _getHistory(const NoParams());
      if (isClosed) return;
      if (edits != _edits) continue;
      return result.fold(_log, emit);
    }
  }

  /// Records [page] (0-based) as the reading position of a chapter with
  /// [pageCount] pages. Reaching the last page finishes the chapter; a
  /// finished chapter stays finished when read again. A [quiet] save does
  /// not ask sync to run; the reader makes a normal save when it closes.
  Future<void> addHistory({
    required String slug,
    required String chapterNumber,
    required ComicDetails comicDetails,
    required String comicSlug,
    required int page,
    required int pageCount,
    bool quiet = false,
  }) {
    final finished =
        page >= pageCount - 1 || (index.chapter(slug)?.isFinished ?? false);
    final entry = ReadHistory(
      slug: slug,
      chapterNumber: chapterNumber,
      readDate: _clock.now(),
      comicDetails: comicDetails,
      comicSlug: comicSlug,
      page: finished ? null : page,
      pageCount: finished ? null : pageCount,
    );
    if (quiet) {
      _quiet[slug] = entry;
    } else {
      _quiet.remove(slug);
    }
    return addHistoryList([entry], quiet: quiet);
  }

  /// Entries saved quietly and not announced to sync yet, by chapter slug.
  final _quiet = <String, ReadHistory>{};

  /// Saves the last quiet [addHistory] of chapter [slug] again, unchanged,
  /// as a normal save so sync sends it. Nothing when there is none.
  Future<void> announce(String slug) async {
    if (_quiet.remove(slug) case final entry?) {
      await addHistoryList([entry]);
    }
  }

  Future<void> addHistoryList(
    List<ReadHistory> history, {
    bool quiet = false,
  }) async {
    final saved = [...history];
    final result = await _saveHistory(saved, quiet: quiet);
    if (result case Left(value: final failure)) {
      _log(failure);
      return load();
    }
    if (saved.isNotEmpty) _edit(withSaved(state, saved));
  }

  /// [current] (newest first) after [saved] was stored, as the repository
  /// reads it back: entries replaced by slug (the last one given wins),
  /// every entry of a saved comic with that comic's last given details,
  /// read dates to the millisecond.
  @visibleForTesting
  static List<ReadHistory> withSaved(
    List<ReadHistory> current,
    List<ReadHistory> saved,
  ) {
    final details = {for (final h in saved) h.comicSlug: h.comicDetails};
    final bySlug = {for (final h in saved) h.slug: h};
    final added = [
      for (final h in bySlug.values)
        h.copyWith(
          readDate: DateTime.fromMillisecondsSinceEpoch(
            h.readDate.millisecondsSinceEpoch,
          ),
          comicDetails: details[h.comicSlug]!,
        ),
    ]..sort(compareNewestFirst);
    final kept = [
      for (final h in current)
        if (!bySlug.containsKey(h.slug))
          switch (details[h.comicSlug]) {
            final d? when !identical(d, h.comicDetails) => h.copyWith(
              comicDetails: d,
            ),
            _ => h,
          },
    ];
    // Both lists are newest first: merge them.
    final merged = <ReadHistory>[];
    var i = 0, j = 0;
    while (i < kept.length && j < added.length) {
      merged.add(
        compareNewestFirst(kept[i], added[j]) <= 0 ? kept[i++] : added[j++],
      );
    }
    return merged
      ..addAll(kept.skip(i))
      ..addAll(added.skip(j));
  }

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

  Future<void> removeHistoryList(List<String> slugs) {
    final removed = slugs.toSet();
    return _thenRemove(
      _removeHistory([...slugs]),
      (h) => removed.contains(h.slug),
    );
  }

  /// Removes every read chapter of one comic.
  Future<void> removeHistoryBySlug(String comicSlug) => _thenRemove(
    _removeComicHistory(comicSlug),
    (h) => h.comicSlug == comicSlug,
  );

  /// Removes every read chapter of each comic, in one write.
  Future<void> markAllUnread(Iterable<String> comicSlugs) {
    final comics = comicSlugs.toSet();
    if (comics.isEmpty) return Future.value();
    return _thenRemove(
      _removeComicHistory.many(comics.toList()),
      (h) => comics.contains(h.comicSlug),
    );
  }

  Future<void> clearHistory() =>
      _thenRemove(_clearHistory(const NoParams()), (_) => true);

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

  /// Drops the entries matching [removed] once [action] succeeded; reloads
  /// when it failed.
  Future<void> _thenRemove(
    Future<Either<Failure, Unit>> action,
    bool Function(ReadHistory entry) removed,
  ) async {
    if ((await action) case Left(value: final failure)) {
      _log(failure);
      return load();
    }
    final kept = [
      for (final h in state)
        if (!removed(h)) h,
    ];
    if (kept.length != state.length) _edit(kept);
  }

  void _edit(List<ReadHistory> history) {
    if (isClosed) return;
    _edits++;
    emit(history);
  }

  void _log(Failure failure) => debugPrint('HistoryCubit: $failure');
}
