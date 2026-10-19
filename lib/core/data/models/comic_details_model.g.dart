// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comic_details_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ComicDetailsModel _$ComicDetailsModelFromJson(Map<String, dynamic> json) =>
    ComicDetailsModel(
      title: json['title'] as String,
      coverImg: json['coverImg'] as String,
      alternativeTitle: json['alternativeTitle'] as String,
      released: json['released'] as String,
      status: json['status'] as String,
      totalChapter: json['totalChapter'] as String,
      author: json['author'] as String,
      type: json['type'] as String,
      rating: json['rating'] as String,
      synopsis: json['synopsis'] as String,
      genres: (json['genres'] as List<dynamic>)
          .map((e) => GenreModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      chapters: (json['chapters'] as List<dynamic>)
          .map((e) => ChapterModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ComicDetailsModelToJson(ComicDetailsModel instance) =>
    <String, dynamic>{
      'title': instance.title,
      'coverImg': instance.coverImg,
      'alternativeTitle': instance.alternativeTitle,
      'released': instance.released,
      'status': instance.status,
      'totalChapter': instance.totalChapter,
      'author': instance.author,
      'type': instance.type,
      'rating': instance.rating,
      'synopsis': instance.synopsis,
      'genres': instance.genres.map((e) => e.toJson()).toList(),
      'chapters': instance.chapters.map((e) => e.toJson()).toList(),
    };

GenreModel _$GenreModelFromJson(Map<String, dynamic> json) =>
    GenreModel(name: json['name'] as String, slug: json['slug'] as String);

Map<String, dynamic> _$GenreModelToJson(GenreModel instance) =>
    <String, dynamic>{'name': instance.name, 'slug': instance.slug};

ChapterModel _$ChapterModelFromJson(Map<String, dynamic> json) => ChapterModel(
  number: json['number'] as String,
  slug: json['slug'] as String,
  date: json['date'] as String,
);

Map<String, dynamic> _$ChapterModelToJson(ChapterModel instance) =>
    <String, dynamic>{
      'number': instance.number,
      'slug': instance.slug,
      'date': instance.date,
    };
