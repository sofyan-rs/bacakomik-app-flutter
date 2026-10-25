// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'series_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SeriesResponse _$SeriesResponseFromJson(Map<String, dynamic> json) =>
    _SeriesResponse(
      title: json['title'] as String,
      slug: json['slug'] as String,
      cover: json['cover'] as String?,
      format: json['format'] as String?,
      status: json['status'] as String?,
      rating: json['rating'] as num?,
      totalChapters: json['totalChapters'] as num?,
      altTitles: (json['altTitles'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$SeriesResponseToJson(_SeriesResponse instance) =>
    <String, dynamic>{
      'title': instance.title,
      'slug': instance.slug,
      'cover': instance.cover,
      'format': instance.format,
      'status': instance.status,
      'rating': instance.rating,
      'totalChapters': instance.totalChapters,
      'altTitles': instance.altTitles,
    };

_SeriesDetailResponse _$SeriesDetailResponseFromJson(
  Map<String, dynamic> json,
) => _SeriesDetailResponse(
  title: json['title'] as String,
  slug: json['slug'] as String,
  cover: json['cover'] as String?,
  nativeTitle: json['nativeTitle'] as String?,
  altTitles: (json['altTitles'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  releaseDate: json['releaseDate'] as String?,
  status: json['status'] as String?,
  author: json['author'] as String?,
  format: json['format'] as String?,
  rating: json['rating'] as num?,
  synopsis: json['synopsis'] as String?,
  genres:
      (json['genres'] as List<dynamic>?)
          ?.map((e) => GenreResponse.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$SeriesDetailResponseToJson(
  _SeriesDetailResponse instance,
) => <String, dynamic>{
  'title': instance.title,
  'slug': instance.slug,
  'cover': instance.cover,
  'nativeTitle': instance.nativeTitle,
  'altTitles': instance.altTitles,
  'releaseDate': instance.releaseDate,
  'status': instance.status,
  'author': instance.author,
  'format': instance.format,
  'rating': instance.rating,
  'synopsis': instance.synopsis,
  'genres': instance.genres.map((e) => e.toJson()).toList(),
};

_GenreResponse _$GenreResponseFromJson(Map<String, dynamic> json) =>
    _GenreResponse(id: _idToString(json['id']), name: json['name'] as String);

Map<String, dynamic> _$GenreResponseToJson(_GenreResponse instance) =>
    <String, dynamic>{'id': instance.id, 'name': instance.name};

_ChapterResponse _$ChapterResponseFromJson(Map<String, dynamic> json) =>
    _ChapterResponse(
      number: json['number'] as num,
      createdAt: json['createdAt'] as String?,
    );

Map<String, dynamic> _$ChapterResponseToJson(_ChapterResponse instance) =>
    <String, dynamic>{
      'number': instance.number,
      'createdAt': instance.createdAt,
    };

_ChapterDetailResponse _$ChapterDetailResponseFromJson(
  Map<String, dynamic> json,
) => _ChapterDetailResponse(
  number: json['number'] as num,
  title: json['title'] as String?,
  prev: json['prev'] as num?,
  next: json['next'] as num?,
  images:
      (json['images'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  headers:
      (json['headers'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ) ??
      const {},
);

Map<String, dynamic> _$ChapterDetailResponseToJson(
  _ChapterDetailResponse instance,
) => <String, dynamic>{
  'number': instance.number,
  'title': instance.title,
  'prev': instance.prev,
  'next': instance.next,
  'images': instance.images,
  'headers': instance.headers,
};
