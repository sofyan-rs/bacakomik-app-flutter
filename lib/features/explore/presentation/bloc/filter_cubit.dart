import 'package:bacakomik_app/core/source/extension_meta.dart';
import 'package:bacakomik_app/features/explore/domain/entities/explore_filter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

@injectable
class FilterCubit extends Cubit<ExploreFilter> {
  FilterCubit() : super(const ExploreFilter());

  /// Another source: its filter groups differ, so filters and search reset.
  void setSource(String source) {
    if (state.source == source) return;
    emit(ExploreFilter(source: source));
  }

  /// Replaces every filter value; keeps the search.
  void setValues(FilterValues values) => emit(state.copyWith(values: values));

  /// Sets one group; keeps the rest.
  void setValue(String key, List<String> value) =>
      emit(state.copyWith(values: {...state.values, key: value}));

  /// Only [genreId] of [source], with every other filter and the search
  /// cleared.
  void showGenre(String source, String genreId) => emit(
    ExploreFilter(
      source: source,
      values: {
        FilterGroup.genreKey: [genreId],
      },
    ),
  );

  /// Title search; keeps the other filters.
  void setQuery(String query) => emit(state.copyWith(query: query));
}
