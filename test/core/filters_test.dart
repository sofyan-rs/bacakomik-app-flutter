import 'package:bacakomik_app/core/constants/filters.dart';
import 'package:flutter_test/flutter_test.dart';

// Enums of GET /series in bacakomik-api's /openapi.json. The API rejects
// unknown values with 400, so the filter options must stay inside them.
const _apiSorts = {
  'latest',
  'newseries',
  'bookmark',
  'popular',
  'rating',
  'az',
};
const _apiStatuses = {'ongoing', 'completed', 'hiatus', 'cancelled'};
const _apiFormats = {'manhwa', 'manhua', 'manga', 'mangatoon', 'webtoon'};

void main() {
  test('sort options are API sort values', () {
    for (final option in Filters.sortbyList) {
      expect(_apiSorts, contains(option.id));
    }
  });

  test('status and type options are API values or "all"', () {
    for (final option in Filters.statusList) {
      expect({..._apiStatuses, 'all'}, contains(option.id));
    }
    for (final option in Filters.typeList) {
      expect({..._apiFormats, 'all'}, contains(option.id));
    }
  });
}
