part of 'home_bloc.dart';

@immutable
sealed class HomeState {}

final class HomeInitial extends HomeState {}

final class HomeLoading extends HomeState {}

final class HomeLoaded extends HomeState {
  final HomeModel home;
  final bool isRefetch;

  HomeLoaded({
    required this.home,
    this.isRefetch = false,
  });
}

final class HomeError extends HomeState {
  final String message;

  HomeError({
    required this.message,
  });
}

final class NoInternet extends HomeState {}
