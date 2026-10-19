part of 'home_bloc.dart';

sealed class HomeEvent {}

final class HomeStarted extends HomeEvent {}

/// Pull-to-refresh: keeps the current data visible while reloading.
final class HomeRefreshed extends HomeEvent {}
