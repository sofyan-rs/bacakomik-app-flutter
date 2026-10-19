import 'package:bacakomik_app/core/presentation/bloc/comic_list_state.dart';
import 'package:bacakomik_app/features/latest/domain/usecases/get_latest_comics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

sealed class LatestEvent {}

final class LatestRequested extends LatestEvent {}

final class LatestNextPageRequested extends LatestEvent {
  LatestNextPageRequested({required this.page});

  final int page;
}

@injectable
class LatestBloc extends Bloc<LatestEvent, ComicListState>
    with ComicListLoader<LatestEvent> {
  LatestBloc(this._getLatest) : super(const ComicListState.initial()) {
    on<LatestRequested>((event, emit) => loadFirstPage(emit, () => _getLatest(1)));
    on<LatestNextPageRequested>(
      (event, emit) => loadNextPage(emit, () => _getLatest(event.page)),
    );
  }

  final GetLatestComics _getLatest;
}
