import 'package:bacakomik_app/core/models/comic_list_model.dart';
import 'package:bacakomik_app/core/utils/connectivity_check.dart';
import 'package:bacakomik_app/data/repository/comic_list_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'comic_list_event.dart';
part 'comic_list_state.dart';

class ComicListBloc extends Bloc<ComicListEvent, ComicListState> {
  final ComicListRepository comicListRepository;
  final _connectivityCheck = ConnectivityCheck();

  ComicListBloc(
    this.comicListRepository,
  ) : super(ComicListInitial()) {
    on<GetComicList>(_getComicList);
  }

  void _getComicList(
    ComicListEvent event,
    Emitter<ComicListState> emit,
  ) async {
    bool isConnected = await _connectivityCheck.checkStatus();
    if (!isConnected) {
      emit(NoInternet());
      return;
    }
    emit(ComicListLoading());
    try {
      final comicList = await comicListRepository.getAllComic();
      emit(ComicListLoaded(comicList: comicList));
    } catch (e) {
      emit(ComicListError(message: e.toString()));
    }
  }

  List<ComicListModel> searchComic(String keyword) {
    final comicList = (state as ComicListLoaded).comicList;
    final searchResult = comicList
        .where((comic) =>
            comic.title.toLowerCase().contains(keyword.toLowerCase()))
        .toList();

    return searchResult;
  }
}
