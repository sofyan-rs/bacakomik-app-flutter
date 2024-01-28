part of 'home_bloc.dart';

@immutable
sealed class HomeState {}

final class HomeInitial extends HomeState {}

final class HomeLoading extends HomeState {}

final class HomeRefetching extends HomeState {
  final HomeModel home;
  HomeRefetching({
    required this.home,
  });
}

final class HomeLoaded extends HomeState {
  final HomeModel home;
  HomeLoaded({
    required this.home,
  });
}

final class HomeError extends HomeState {
  final String message;
  HomeError({
    required this.message,
  });
}
