import 'package:bacakomik_app/core/models/comic_details_model/comic_details_model.dart';
import 'package:bacakomik_app/core/models/comic_latest_history_model.dart';
import 'package:bacakomik_app/core/models/history_model.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

class HistoryCubit extends HydratedCubit<List<HistoryModel>> {
  HistoryCubit() : super([]);

  void addHistory(String chapterNumber, String slug,
      ComicDetailsModel comicDetails, String comicSlug) {
    final newState = state;
    final history = HistoryModel(
      slug: slug,
      chapterNumber: chapterNumber,
      readDate: DateTime.now(),
      comicDetails: comicDetails,
      comicSlug: comicSlug,
    );
    final isExist = newState.indexWhere((element) => element.slug == slug);
    if (isExist != -1) {
      newState.removeAt(isExist);
    }
    emit([history, ...newState]);
  }

  void removeHistory(String slug) {
    final newState = state;
    newState.removeWhere((element) => element.slug == slug);
    emit([...newState]);
  }

  void clearHistory() {
    emit([]);
  }

  void setHistory(List<HistoryModel> histories) {
    emit([...histories]);
  }

  bool isInHistory(String slug) {
    return state.any((element) => element.slug == slug);
  }

  HistoryModel getLatestHistory() {
    return state.first;
  }

  List<ComicLatestHistoryModel> getLatestHistories() {
    List<ComicLatestHistoryModel> latestHistories = [];
    final history = state;
    for (var i = 0; i < history.length; i++) {
      final isComicExist = latestHistories
          .indexWhere((element) => element.comicSlug == history[i].comicSlug);
      if (isComicExist != -1) {
        latestHistories[isComicExist] = ComicLatestHistoryModel(
          comicSlug: history[i].comicSlug,
          comicDetails: history[i].comicDetails,
          latestHistory: history[i],
        );
      } else {
        latestHistories.add(ComicLatestHistoryModel(
          comicSlug: history[i].comicSlug,
          comicDetails: history[i].comicDetails,
          latestHistory: history[i],
        ));
      }
    }
    return latestHistories;
  }

  HistoryModel getLatestHistoryBySlug(String slug) {
    return state.firstWhere((element) => element.slug == slug);
  }

  @override
  List<HistoryModel>? fromJson(Map<String, dynamic> json) {
    if (json['history_read'] != null) {
      return List<HistoryModel>.from(
          json['favorites_comic'].map((x) => HistoryModel.fromJson(x)));
    }
    return null;
  }

  @override
  Map<String, dynamic>? toJson(List<HistoryModel> state) {
    return {
      'history_read': state.map((e) => e.toJson()).toList(),
    };
  }
}
