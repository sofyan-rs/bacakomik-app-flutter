import 'package:freezed_annotation/freezed_annotation.dart';

part 'explore_filter.freezed.dart';

/// Explore filter. `all` (type/status) and `default` (sortBy) mean
/// "no filter".
@freezed
abstract class ExploreFilter with _$ExploreFilter {
  const factory ExploreFilter({
    @Default('latest') String sortBy,
    @Default('all') String type,
    @Default('all') String status,
    @Default([]) List<String> genres,
  }) = _ExploreFilter;
}
