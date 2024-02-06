part of 'explore_bloc.dart';

@immutable
sealed class ExploreEvent {}

final class GetExploreResult extends ExploreEvent {
  final String sortBy;
  final String status;
  final String type;
  final List<String> genres;
  final int page;

  GetExploreResult({
    required this.sortBy,
    required this.status,
    required this.type,
    required this.genres,
    required this.page,
  });
}

final class GetExploreResultNext extends ExploreEvent {
  final String sortBy;
  final String status;
  final String type;
  final List<String> genres;
  final int page;

  GetExploreResultNext({
    required this.sortBy,
    required this.status,
    required this.type,
    required this.genres,
    required this.page,
  });
}

final class ResetExploreResult extends ExploreEvent {}
