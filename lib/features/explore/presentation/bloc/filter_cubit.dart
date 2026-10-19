import 'package:bacakomik_app/features/explore/domain/entities/explore_filter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

@injectable
class FilterCubit extends Cubit<ExploreFilter> {
  FilterCubit() : super(const ExploreFilter());

  void setFilter({
    required String sortBy,
    required String type,
    required String status,
    required List<String> genres,
  }) {
    emit(state.copyWith(
      sortBy: sortBy,
      type: type,
      status: status,
      genres: genres,
    ));
  }

  /// Title search; keeps the other filters.
  void setQuery(String query) => emit(state.copyWith(query: query));
}
