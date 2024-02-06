part of 'filter_cubit.dart';

class FilterState {
  final String sortBy;
  final String type;
  final String status;
  final List<String> genres;

  FilterState({
    required this.sortBy,
    required this.type,
    required this.status,
    required this.genres,
  });

  FilterState copyWith({
    String? sortBy,
    String? type,
    String? status,
    List<String>? genres,
  }) {
    return FilterState(
      sortBy: sortBy ?? this.sortBy,
      type: type ?? this.type,
      status: status ?? this.status,
      genres: genres ?? this.genres,
    );
  }
}
