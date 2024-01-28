import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bacakomik_app/core/models/latest_model.dart';
import 'package:bacakomik_app/data/repository/latest_repository.dart';

part 'latest_more_event.dart';
part 'latest_more_state.dart';

class LatestMoreBloc extends Bloc<LatestMoreEvent, LatestMoreState> {
  final LatestRepository latestRepository;

  LatestMoreBloc(
    this.latestRepository,
  ) : super(LatestMoreInitial()) {
    on<GetMoreLatest>(_getLatest);
    on<GetMoreLatestNext>(_getMoreLatest);
  }

  void _getLatest(
    LatestMoreEvent event,
    Emitter<LatestMoreState> emit,
  ) async {
    emit(LatestMoreLoading());
    try {
      final latest = await latestRepository.getLatest(1);
      emit(LatestMoreLoaded(latest: latest));
    } catch (e) {
      emit(LatestMoreError(message: e.toString()));
    }
  }

  void _getMoreLatest(
    LatestMoreEvent event,
    Emitter<LatestMoreState> emit,
  ) async {
    try {
      final page = (event as GetMoreLatestNext).page;
      final latest = await latestRepository.getLatest(page);
      final state = this.state as LatestMoreLoaded;
      emit(LatestMoreLoaded(latest: [...state.latest, ...latest]));
    } catch (e) {
      emit(LatestMoreError(message: e.toString()));
    }
  }
}
