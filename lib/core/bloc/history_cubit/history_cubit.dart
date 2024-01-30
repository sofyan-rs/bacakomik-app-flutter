import 'package:bacakomik_app/core/models/history_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HistoryCubit extends Cubit<List<HistoryModel>> {
  HistoryCubit() : super([]);

  void addHistory(HistoryModel history) {
    state.add(history);
    emit(state);
  }

  void removeHistory(HistoryModel history) {
    state.remove(history);
    emit(state);
  }

  void clearHistory() {
    state.clear();
    emit(state);
  }

  void setHistory(List<HistoryModel> histories) {
    state.addAll(histories);
    emit(state);
  }

  bool isHistory(HistoryModel history) {
    return state.contains(history);
  }

  List<HistoryModel> getHistory() {
    return state;
  }

  bool isEmpty() {
    return state.isEmpty;
  }

  bool isNotEmpty() {
    return state.isNotEmpty;
  }

  int getLength() {
    return state.length;
  }
}
