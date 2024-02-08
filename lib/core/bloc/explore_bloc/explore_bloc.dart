// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bacakomik_app/core/models/comic_model.dart';
import 'package:bacakomik_app/core/utils/connectivity_check.dart';
import 'package:bacakomik_app/data/repository/explore_data_repository.dart';

part 'explore_event.dart';
part 'explore_state.dart';

class ExploreBloc extends Bloc<ExploreEvent, ExploreState> {
  final ExploreRepository exploreRepository;
  final _connectivityCheck = ConnectivityCheck();

  ExploreBloc(
    this.exploreRepository,
  ) : super(ExploreInitial()) {
    on<GetExploreResult>(_getResult);
    on<GetExploreResultNext>(_getResultNext);
  }

  // @override
  // void onChange(Change<ExploreState> change) {
  //   print(change);
  //   super.onChange(change);
  // }

  // @override
  // void onTransition(Transition<ExploreEvent, ExploreState> transition) {
  //   print(transition);
  //   super.onTransition(transition);
  // }

  void _getResult(
    ExploreEvent event,
    Emitter<ExploreState> emit,
  ) async {
    bool isConnected = await _connectivityCheck.checkStatus();
    if (!isConnected) {
      emit(NoInternet());
      return;
    }
    emit(ExploreLoading());
    try {
      final sortby = (event as GetExploreResult).sortBy;
      final status = (event).status;
      final type = (event).type;
      final genres = (event).genres;
      final page = (event).page;
      final result = await exploreRepository.getResult(
        sortby,
        status,
        type,
        genres,
        page,
      );
      emit(ExploreLoaded(result: result));
    } catch (e) {
      emit(ExploreError(message: e.toString()));
    }
  }

  void _getResultNext(
    ExploreEvent event,
    Emitter<ExploreState> emit,
  ) async {
    bool isConnected = await _connectivityCheck.checkStatus();
    if (!isConnected) {
      emit(NoInternet());
      return;
    }
    final state = this.state as ExploreLoaded;
    emit(ExploreLoaded(result: state.result, isLoadMore: true));
    try {
      final sortby = (event as GetExploreResultNext).sortBy;
      final status = (event).status;
      final type = (event).type;
      final genres = (event).genres;
      final page = (event).page;
      final result = await exploreRepository.getResult(
        sortby,
        status,
        type,
        genres,
        page,
      );
      emit(ExploreLoaded(
        result: [...state.result, ...result],
        isLoadMore: false,
      ));
    } catch (e) {
      emit(ExploreError(message: e.toString()));
    }
  }
}
