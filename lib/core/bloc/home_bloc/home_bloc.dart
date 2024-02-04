import 'package:bacakomik_app/core/models/home_model.dart';
import 'package:bacakomik_app/core/utils/connectivity_check.dart';
import 'package:bacakomik_app/data/repository/home_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final HomeRepository homeRepository;
  final _connectivityCheck = ConnectivityCheck();

  HomeBloc(
    this.homeRepository,
  ) : super(HomeInitial()) {
    on<GetHome>(_getHome);
    on<RefetchHome>(_refetchHome);
  }

  // @override
  // void onChange(Change<HomeState> change) {
  //   print(change);
  //   super.onChange(change);
  // }

  // @override
  // void onTransition(Transition<HomeEvent, HomeState> transition) {
  //   print(transition);
  //   super.onTransition(transition);
  // }

  void _getHome(
    HomeEvent event,
    Emitter<HomeState> emit,
  ) async {
    bool isConnected = await _connectivityCheck.checkStatus();
    if (!isConnected) {
      emit(NoInternet());
      return;
    }
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
    // bool isConnected = await _connectivityCheck.checkStatus();
    // print(isConnected);
    // if (!isConnected) {
    //   emit(NoInternet());
    //   return;
    // }
    final state = this.state as HomeLoaded;
    emit(HomeLoaded(
      home: state.home,
      isRefetch: true,
    ));
    try {
      final home = await homeRepository.getHome();
      Future.delayed(const Duration(seconds: 10));
      emit(HomeLoaded(home: home));
    } catch (e) {
      emit(HomeError(message: e.toString()));
    }
  }
}
