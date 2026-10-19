import 'package:bacakomik_app/core/presentation/bloc/comic_list_state.dart';
import 'package:bacakomik_app/features/search/domain/usecases/search_comics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

sealed class SearchEvent {
  const SearchEvent(this.keyword, this.page);

  final String keyword;
  final int page;
}

final class SearchRequested extends SearchEvent {
  const SearchRequested({required String keyword, int page = 1})
      : super(keyword, page);
}

final class SearchNextPageRequested extends SearchEvent {
  const SearchNextPageRequested({required String keyword, required int page})
      : super(keyword, page);
}

@injectable
class SearchBloc extends Bloc<SearchEvent, ComicListState>
    with ComicListLoader<SearchEvent> {
  SearchBloc(this._searchComics) : super(const ComicListState.initial()) {
    on<SearchRequested>(
      (event, emit) => loadFirstPage(emit, () => _search(event)),
    );
    on<SearchNextPageRequested>(
      (event, emit) => loadNextPage(emit, () => _search(event)),
    );
  }

  final SearchComics _searchComics;

  ComicPage _search(SearchEvent event) =>
      _searchComics((keyword: event.keyword, page: event.page));
}
