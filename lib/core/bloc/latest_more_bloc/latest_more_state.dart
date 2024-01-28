part of 'latest_more_bloc.dart';

@immutable
sealed class LatestMoreState {}

final class LatestMoreInitial extends LatestMoreState {}

final class LatestMoreLoading extends LatestMoreState {}

final class LatestMoreLoaded extends LatestMoreState {
  final List<LatestModel> latest;
  LatestMoreLoaded({
    required this.latest,
  });
}

final class LatestMoreError extends LatestMoreState {
  final String message;
  LatestMoreError({
    required this.message,
  });
}
