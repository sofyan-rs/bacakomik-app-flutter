import 'package:bacakomik_app/core/domain/entities/comic.dart';
import 'package:bacakomik_app/core/domain/entities/comic_details.dart';
import 'package:bacakomik_app/core/utils/api_format.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'series_response.freezed.dart';
part 'series_response.g.dart';

/// Item of `/series` and `/lists/{kind}`.
@freezed
abstract class SeriesResponse with _$SeriesResponse {
  const SeriesResponse._();

  const factory SeriesResponse({
    required String title,
    required String slug,
    String? cover,
    String? format,
    String? status,
    num? rating,
    num? totalChapters,
  }) = _SeriesResponse;

  factory SeriesResponse.fromJson(Map<String, dynamic> json) =>
      _$SeriesResponseFromJson(json);

  Comic toEntity() => Comic(
        title: title,
        coverImg: cover ?? '',
        slug: slug,
        type: ApiFormat.capitalize(format),
        completed: status == 'completed',
        rating: ApiFormat.rating(rating),
        latestChapter: ApiFormat.number(totalChapters),
      );
}

/// Body of `/series/{slug}`.
@freezed
abstract class SeriesDetailResponse with _$SeriesDetailResponse {
  const SeriesDetailResponse._();

  const factory SeriesDetailResponse({
    required String title,
    required String slug,
    String? cover,
    String? nativeTitle,
    String? releaseDate,
    String? status,
    String? author,
    String? format,
    num? rating,
    String? synopsis,
    @Default([]) List<GenreResponse> genres,
  }) = _SeriesDetailResponse;

  factory SeriesDetailResponse.fromJson(Map<String, dynamic> json) =>
      _$SeriesDetailResponseFromJson(json);

  ComicDetails toEntity(List<ChapterResponse> chapters) => ComicDetails(
        title: title,
        coverImg: cover ?? '',
        alternativeTitle: nativeTitle ?? '-',
        released: releaseDate ?? '-',
        status: ApiFormat.capitalize(status),
        totalChapter: chapters.length.toString(),
        author: author ?? '-',
        type: ApiFormat.capitalize(format),
        rating: ApiFormat.rating(rating),
        synopsis: synopsis?.trim() ?? '',
        genres: genres.map((e) => e.toEntity()).toList(),
        chapters: chapters.map((e) => e.toEntity(slug)).toList(),
      );
}

@freezed
abstract class GenreResponse with _$GenreResponse {
  const GenreResponse._();

  const factory GenreResponse({
    @JsonKey(fromJson: _idToString) required String id,
    required String name,
  }) = _GenreResponse;

  factory GenreResponse.fromJson(Map<String, dynamic> json) =>
      _$GenreResponseFromJson(json);

  Genre toEntity() => Genre(name: name, slug: id);
}

/// Item of `/series/{slug}/chapters`.
@freezed
abstract class ChapterResponse with _$ChapterResponse {
  const ChapterResponse._();

  const factory ChapterResponse({
    required num number,
    String? createdAt,
  }) = _ChapterResponse;

  factory ChapterResponse.fromJson(Map<String, dynamic> json) =>
      _$ChapterResponseFromJson(json);

  Chapter toEntity(String seriesSlug) => Chapter(
        number: ApiFormat.number(number),
        slug: ApiFormat.chapterSlug(seriesSlug, number),
        date: ApiFormat.relativeDate(createdAt),
      );
}

/// Body of `/series/{slug}/chapters/{number}`.
@freezed
abstract class ChapterDetailResponse with _$ChapterDetailResponse {
  const factory ChapterDetailResponse({
    required num number,
    String? title,
    num? prev,
    num? next,
    @Default([]) List<String> images,
  }) = _ChapterDetailResponse;

  factory ChapterDetailResponse.fromJson(Map<String, dynamic> json) =>
      _$ChapterDetailResponseFromJson(json);
}

String _idToString(Object? id) => id.toString();
