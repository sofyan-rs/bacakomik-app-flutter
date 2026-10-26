import 'package:freezed_annotation/freezed_annotation.dart';

part 'comic_details.freezed.dart';

/// Known values of [ComicDetails.source], which holds a source id.
abstract final class ComicSource {
  /// Source of everything stored before the app had sources. Such comics
  /// carry no source, or this one when an older migration could not match
  /// them; MigrateSnapshot moves them under this source's keys.
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

    /// Id of the source the details came from. Null in data stored before
    /// the API switched source; see [ComicSource.legacy].
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

    /// Shown instead of "Chapter [number]" when the number was made up for
    /// a chapter without one (Mihon sources).
    String? title,
  }) = _Chapter;
}
