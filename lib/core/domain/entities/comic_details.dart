import 'package:freezed_annotation/freezed_annotation.dart';

part 'comic_details.freezed.dart';

/// Values of [ComicDetails.source].
abstract final class ComicSource {
  /// Source of the current API (bacakomik.my).
  static const current = 'bacakomik';

  /// The API's previous source. Stored comics that could not be found in the
  /// current source are marked with it, so the migration does not retry them.
  static const legacy = 'voratoon';
}

@freezed
abstract class ComicDetails with _$ComicDetails {
  const factory ComicDetails({
    required String title,
    required String coverImg,
    required String alternativeTitle,
    required String released,
    required String status,
    required String totalChapter,
    required String author,
    required String type,
    required String rating,
    required String synopsis,
    required List<Genre> genres,
    required List<Chapter> chapters,

    /// Upstream the details came from, see [ComicSource]. Null in data
    /// stored before the API switched source; such comics still use the old
    /// source's slugs and are migrated by MigrateLibrary.
    String? source,
  }) = _ComicDetails;
}

@freezed
abstract class Genre with _$Genre {
  const factory Genre({required String name, required String slug}) = _Genre;
}

@freezed
abstract class Chapter with _$Chapter {
  const factory Chapter({
    required String number,

    /// Chapter slug in the form `seriesSlug/number`.
    required String slug,
    required String date,
  }) = _Chapter;
}
