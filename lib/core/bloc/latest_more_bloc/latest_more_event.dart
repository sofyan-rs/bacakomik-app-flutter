part of 'latest_more_bloc.dart';

@immutable
sealed class LatestMoreEvent {}

final class GetMoreLatest extends LatestMoreEvent {}

final class GetMoreLatestNext extends LatestMoreEvent {
  final int page;

  GetMoreLatestNext({
    required this.page,
  });
}
