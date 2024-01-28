import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

part 'search_comic_event.dart';
part 'search_comic_state.dart';

class SearchComicBloc extends Bloc<SearchComicEvent, SearchComicState> {
  SearchComicBloc() : super(SearchComicInitial()) {
    on<SearchComicEvent>((event, emit) {
      // TODO: implement event handler
    });
  }
}
