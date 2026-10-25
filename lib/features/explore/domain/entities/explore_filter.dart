import 'package:freezed_annotation/freezed_annotation.dart';

part 'explore_filter.freezed.dart';

/// Explore filter and search for one [source]. [values] holds the picked
/// values per filter group of the source; a group left out uses its
/// default, and an empty [query] means no search. Groups differ per source,
/// so changing source resets the filter.
@freezed
abstract class ExploreFilter with _$ExploreFilter {
  const factory ExploreFilter({
    @Default('') String source,
    @Default({}) Map<String, List<String>> values,

    /// Title search.
    @Default('') String query,
  }) = _ExploreFilter;
}
