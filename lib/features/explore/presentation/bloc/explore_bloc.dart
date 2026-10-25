import 'package:bacakomik_app/core/presentation/bloc/comic_list_state.dart';
import 'package:bacakomik_app/features/explore/domain/entities/explore_filter.dart';
import 'package:bacakomik_app/features/explore/domain/usecases/explore_comics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

sealed class ExploreEvent {
  const ExploreEvent(this.filter, this.page);

  final ExploreFilter filter;
  final int page;
}

final class ExploreRequested extends ExploreEvent {
  const ExploreRequested({required ExploreFilter filter, int page = 1})
    : super(filter, page);
}

final class ExploreNextPageRequested extends ExploreEvent {
  const ExploreNextPageRequested({
    required ExploreFilter filter,
    required int page,
  }) : super(filter, page);
}

@injectable
class ExploreBloc extends Bloc<ExploreEvent, ComicListState>
    with ComicListLoader<ExploreEvent> {
  ExploreBloc(this._exploreComics) : super(const ComicListState.initial()) {
    // One request at a time, in order: while typing a search, an older
    // response must not replace a newer one.
    on<ExploreRequested>(
      (event, emit) => loadFirstPage(emit, () => _explore(event)),
      transformer: (events, mapper) => events.asyncExpand(mapper),
    );
    on<ExploreNextPageRequested>(
      (event, emit) => loadNextPage(emit, () => _explore(event)),
    );
  }

  final ExploreComics _exploreComics;

  ComicPage _explore(ExploreEvent event) =>
      _exploreComics((filter: event.filter, page: event.page));
}
