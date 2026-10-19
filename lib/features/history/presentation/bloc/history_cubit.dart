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

  Future<void> addHistory({
    required String slug,
    required String chapterNumber,
    required ComicDetails comicDetails,
    required String comicSlug,
  }) =>
      addHistoryList([
        ReadHistory(
          slug: slug,
          chapterNumber: chapterNumber,
          readDate: _clock.now(),
          comicDetails: comicDetails,
          comicSlug: comicSlug,
        ),
      ]);

  Future<void> addHistoryList(List<ReadHistory> history) =>
      _thenReload(_saveHistory([...history]));

  Future<void> removeHistory(String slug) => removeHistoryList([slug]);

  Future<void> removeHistoryList(List<String> slugs) =>
      _thenReload(_removeHistory([...slugs]));

  /// Removes every read chapter of one comic.
  Future<void> removeHistoryBySlug(String comicSlug) =>
      _thenReload(_removeComicHistory(comicSlug));

  Future<void> clearHistory() => _thenReload(_clearHistory(const NoParams()));

  bool isInHistory(String slug) => state.containsChapter(slug);

  /// Only valid when [state] is not empty.
  ReadHistory get latestHistory => state.latest!;

  int getHistoryCountBySlug(String comicSlug) => state.countOf(comicSlug);

  ReadHistory? getLatestHistoryBySlug(String comicSlug) =>
      state.latestOf(comicSlug);

  List<ComicLatestHistory> get latestHistories => state.latestPerComic;

  Future<void> _thenReload(Future<Either<Failure, Unit>> action) async {
    (await action).fold(_log, (_) {});
    await load();
  }

  void _log(Failure failure) => debugPrint('HistoryCubit: $failure');
}
