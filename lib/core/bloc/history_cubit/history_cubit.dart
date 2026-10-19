import 'package:bacakomik_app/core/models/comic_details_model/comic_details_model.dart';
import 'package:bacakomik_app/core/models/comic_latest_history_model.dart';
import 'package:bacakomik_app/core/models/history_model.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

class HistoryCubit extends HydratedCubit<List<HistoryModel>> {
  HistoryCubit() : super([]);

  void addHistory({
    required String slug,
    required String chapterNumber,
    required ComicDetailsModel comicDetails,
    required String comicSlug,
  }) {
    final history = HistoryModel(
      slug: slug,
      chapterNumber: chapterNumber,
      readDate: DateTime.now(),
      comicDetails: comicDetails,
      comicSlug: comicSlug,
    );
    emit([history, ...state.where((element) => element.slug != slug)]);
  }

  void addHistoryList(List<HistoryModel> histories) {
    final slugs = histories.map((e) => e.slug).toSet();
    emit([
      ...state.where((element) => !slugs.contains(element.slug)),
      ...histories,
    ]);
  }

  void removeHistory(String slug) {
    emit(state.where((element) => element.slug != slug).toList());
  }

  void removeHistoryList(List<String> slugs) {
    emit(state.where((element) => !slugs.contains(element.slug)).toList());
  }

  void removeHistoryBySlug(String comicSlug) {
    emit(state.where((element) => element.comicSlug != comicSlug).toList());
  }

  void clearHistory() {
    emit([]);
  }

  void setHistory(List<HistoryModel> histories) {
    final newState = [...state];
    for (final history in histories) {
      newState.removeWhere((element) => element.slug == history.slug);
      newState.add(history);
    }
    emit(newState);
  }

  bool isInHistory(String slug) {
    return state.any((element) => element.slug == slug);
  }

  /// History sorted newest first, without mutating [state].
  List<HistoryModel> get _sortedByReadDate =>
      [...state]..sort((a, b) => b.readDate.compareTo(a.readDate));

  HistoryModel get latestHistory => _sortedByReadDate.first;

  int getHistoryCountBySlug(String comicSlug) {
    return state.where((element) => element.comicSlug == comicSlug).length;
  }

  HistoryModel? getLatestHistoryBySlug(String comicSlug) {
    for (final history in _sortedByReadDate) {
      if (history.comicSlug == comicSlug) return history;
    }
    return null;
  }

  List<ComicLatestHistoryModel> get latestHistories {
    final latestHistories = <ComicLatestHistoryModel>[];
    final seen = <String>{};
    for (final history in _sortedByReadDate) {
      if (seen.add(history.comicSlug)) {
        latestHistories.add(
          ComicLatestHistoryModel(
            comicSlug: history.comicSlug,
            comicDetails: history.comicDetails,
            latestHistory: history,
          ),
        );
      }
    }
    return latestHistories;
  }

  @override
  List<HistoryModel>? fromJson(Map<String, dynamic> json) {
    if (json['history_read'] != null) {
      return List<HistoryModel>.from(
        json['history_read'].map((x) => HistoryModel.fromJson(x)),
      );
    }
    return null;
  }

  @override
  Map<String, dynamic>? toJson(List<HistoryModel> state) {
    return {'history_read': state.map((e) => e.toJson()).toList()};
  }
}
