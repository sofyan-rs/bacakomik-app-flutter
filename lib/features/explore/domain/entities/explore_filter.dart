import 'package:freezed_annotation/freezed_annotation.dart';

part 'explore_filter.freezed.dart';

/// Explore filter and search. `all` (type/status), `default` (sortBy) and an
/// empty [query] mean "no filter". The API applies the title search and the
/// filters together.
@freezed
abstract class ExploreFilter with _$ExploreFilter {
  const factory ExploreFilter({
    @Default('latest') String sortBy,
    @Default('all') String type,
    @Default('all') String status,
    @Default([]) List<String> genres,

    /// Title search, sent as `q`.
    @Default('') String query,
  }) = _ExploreFilter;
}
