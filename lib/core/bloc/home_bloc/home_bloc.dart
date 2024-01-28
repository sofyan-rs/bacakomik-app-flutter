import 'package:bacakomik_app/core/models/home_model.dart';
import 'package:bacakomik_app/data/repository/home_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final HomeRepository homeRepository;
  HomeBloc(
    this.homeRepository,
  ) : super(HomeInitial()) {
    on<GetHome>(_getHome);
    on<RefetchHome>(_refetchHome);
  }

  @override
  void onChange(Change<HomeState> change) {
    print(change);
    super.onChange(change);
  }

  @override
  void onTransition(Transition<HomeEvent, HomeState> transition) {
    print(transition);
    super.onTransition(transition);
  }

  void _getHome(
    HomeEvent event,
    Emitter<HomeState> emit,
  ) async {
    emit(HomeLoading());
    try {
      final home = await homeRepository.getHome();
      emit(HomeLoaded(home: home));
    } catch (e) {
      emit(HomeError(message: e.toString()));
    }
  }

  void _refetchHome(
    HomeEvent event,
    Emitter<HomeState> emit,
  ) async {
    final state = this.state as HomeLoaded;
    emit(HomeRefetching(
      home: state.home,
    ));
    try {
      final home = await homeRepository.getHome();
      emit(HomeLoaded(home: home));
    } catch (e) {
      emit(HomeError(message: e.toString()));
    }
  }
}
