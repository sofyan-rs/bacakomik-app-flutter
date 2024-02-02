part of 'latest_more_bloc.dart';

@immutable
sealed class LatestMoreState {}

final class LatestMoreInitial extends LatestMoreState {}

final class LatestMoreLoading extends LatestMoreState {}

final class LatestMoreLoaded extends LatestMoreState {
  final List<ComicModel> latest;
  final bool isLoadMore;

  LatestMoreLoaded({
    required this.latest,
    this.isLoadMore = false,
  });
}

final class LatestMoreError extends LatestMoreState {
  final String message;

  LatestMoreError({
    required this.message,
  });
}

final class NoInternet extends LatestMoreState {}
