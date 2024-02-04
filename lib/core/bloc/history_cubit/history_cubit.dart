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

  addHistoryList(List<HistoryModel> histories) {
    final newState = state;
    for (var i = 0; i < histories.length; i++) {
      final isExist =
          newState.indexWhere((element) => element.slug == histories[i].slug);
      if (isExist != -1) {
        newState.removeAt(isExist);
      }
    }
    newState.addAll(histories);
    emit([...newState]);
  }

  void removeHistory(String slug) {
    final newState = state;
    newState.removeWhere((element) => element.slug == slug);
    emit([...newState]);
  }

  void removeHistoryList(List<String> slugs) {
    final newState = state;
    newState.removeWhere((element) => slugs.contains(element.slug));
    emit([...newState]);
  }

  void removeHistoryBySlug(String comicSlug) {
    final newState = state;
    newState.removeWhere((element) => element.comicSlug == comicSlug);
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

  HistoryModel get latestHistory {
    List<HistoryModel> sortList() {
      final sortedList = state;
      sortedList.sort((a, b) => a.readDate.compareTo(b.readDate));
      return sortedList.reversed.toList();
    }

    return sortList().first;
  }

  int getHistoryCountBySlug(String comicSlug) {
    return state.where((element) => element.comicSlug == comicSlug).length;
  }

  HistoryModel? getLatestHistoryBySlug(String comicSlug) {
    try {
      List<HistoryModel> sortList() {
        final sortedList = state;
        sortedList.sort((a, b) => a.readDate.compareTo(b.readDate));
        return sortedList.reversed.toList();
      }

      return sortList().firstWhere((element) => element.comicSlug == comicSlug);
    } catch (e) {
      return null;
    }
  }

  List<ComicLatestHistoryModel> get latestHistories {
    List<ComicLatestHistoryModel> latestHistories = [];
    List<HistoryModel> sortList() {
      final sortedList = state;
      sortedList.sort((a, b) => a.readDate.compareTo(b.readDate));
      return sortedList.reversed.toList();
    }

    final history = sortList();
    for (var i = 0; i < history.length; i++) {
      final isComicExist = latestHistories
          .indexWhere((element) => element.comicSlug == history[i].comicSlug);
      if (isComicExist == -1) {
        latestHistories.add(ComicLatestHistoryModel(
          comicSlug: history[i].comicSlug,
          comicDetails: history[i].comicDetails,
          latestHistory: history[i],
        ));
      }
    }
    return latestHistories;
  }

  @override
  List<HistoryModel>? fromJson(Map<String, dynamic> json) {
    if (json['history_read'] != null) {
      return List<HistoryModel>.from(
          json['history_read'].map((x) => HistoryModel.fromJson(x)));
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
