part of 'explore_bloc.dart';

@immutable
sealed class ExploreState {}

final class ExploreInitial extends ExploreState {}

final class ExploreLoading extends ExploreState {}

final class ExploreLoaded extends ExploreState {
  final List<ComicModel> result;
  final bool isLoadMore;

  ExploreLoaded({
    required this.result,
    this.isLoadMore = false,
  });
}

final class ExploreError extends ExploreState {
  final String message;
  ExploreError({
    required this.message,
  });
}

final class NoInternet extends ExploreState {}