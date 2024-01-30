import 'package:bacakomik_app/core/models/comic_model.dart';
import 'package:bacakomik_app/data/repository/search_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'search_comic_event.dart';
part 'search_comic_state.dart';

class SearchComicBloc extends Bloc<SearchComicEvent, SearchComicState> {
  final SearchRepository searchRepository;

  SearchComicBloc(
    this.searchRepository,
  ) : super(SearchComicInitial()) {
    on<GetSearchResult>(_getSearchResult);
    on<GetSearchResultNext>(_getSearchResultNext);
  }

  @override
  void onChange(Change<SearchComicState> change) {
    print(change);
    super.onChange(change);
  }

  @override
  void onTransition(Transition<SearchComicEvent, SearchComicState> transition) {
    print(transition);
    super.onTransition(transition);
  }

  void _getSearchResult(
    SearchComicEvent event,
    Emitter<SearchComicState> emit,
  ) async {
    emit(SearchComicLoading());
    try {
      final keyword = (event as GetSearchResult).keyword;
      final page = (event).page;
      final result = await searchRepository.getSearchResult(
        keyword,
        page,
      );
      emit(SearchComicLoaded(result: result));
    } catch (e) {
      emit(SearchComicError(message: e.toString()));
    }
  }

  void _getSearchResultNext(
    SearchComicEvent event,
    Emitter<SearchComicState> emit,
  ) async {
    final state = this.state as SearchComicLoaded;
    emit(SearchComicLoaded(result: state.result, isLoadMore: true));
    try {
      final keyword = (event as GetSearchResultNext).keyword;
      final page = (event).page;
      final result = await searchRepository.getSearchResult(
        keyword,
        page,
      );

      emit(
        SearchComicLoaded(
          result: [...state.result, ...result],
          isLoadMore: false,
        ),
      );
    } catch (e) {
      emit(SearchComicError(message: e.toString()));
    }
  }
}
