part of 'home_bloc.dart';

@immutable
sealed class HomeEvent {}

final class GetHome extends HomeEvent {}

final class RefetchHome extends HomeEvent {}
