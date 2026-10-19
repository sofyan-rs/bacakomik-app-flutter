import 'package:bacakomik_app/core/error/failures.dart';
import 'package:bacakomik_app/core/usecase/usecase.dart';
import 'package:bacakomik_app/features/home/domain/entities/home.dart';
import 'package:bacakomik_app/features/home/domain/usecases/get_home.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

part 'home_event.dart';
part 'home_state.dart';
part 'home_bloc.freezed.dart';

@injectable
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc(this._getHome) : super(const HomeState.initial()) {
    on<HomeStarted>(_onStarted);
    on<HomeRefreshed>(_onRefreshed);
  }

  final GetHome _getHome;

  Future<void> _onStarted(HomeStarted event, Emitter<HomeState> emit) async {
    emit(const HomeState.loading());
    final result = await _getHome(const NoParams());
    emit(result.fold(_failureState, (home) => HomeState.loaded(home: home)));
  }

  Future<void> _onRefreshed(
    HomeRefreshed event,
    Emitter<HomeState> emit,
  ) async {
    final current = state;
    if (current is! HomeLoaded) return _onStarted(HomeStarted(), emit);

    emit(current.copyWith(isRefetch: true));
    final result = await _getHome(const NoParams());
    emit(result.fold(_failureState, (home) => HomeState.loaded(home: home)));
  }

  HomeState _failureState(Failure failure) => switch (failure) {
        NetworkFailure() => const HomeState.noInternet(),
        _ => HomeState.error(message: failure.message),
      };
}
