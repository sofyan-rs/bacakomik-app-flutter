// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bookmark_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BookmarkModel _$BookmarkModelFromJson(Map<String, dynamic> json) =>
    BookmarkModel(
      slug: json['slug'] as String,
      comicDetails: ComicDetailsModel.fromJson(
        json['comicDetails'] as Map<String, dynamic>,
      ),
      updatedDate: const EpochMillisConverter().fromJson(
        (json['updatedDate'] as num).toInt(),
      ),
      addedDate: _$JsonConverterFromJson<int, DateTime>(
        json['addedDate'],
        const EpochMillisConverter().fromJson,
      ),
    );

Map<String, dynamic> _$BookmarkModelToJson(BookmarkModel instance) =>
    <String, dynamic>{
      'slug': instance.slug,
      'comicDetails': instance.comicDetails.toJson(),
      'updatedDate': const EpochMillisConverter().toJson(instance.updatedDate),
      'addedDate': ?_$JsonConverterToJson<int, DateTime>(
        instance.addedDate,
        const EpochMillisConverter().toJson,
      ),
    };

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) => json == null ? null : fromJson(json as Json);

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) => value == null ? null : toJson(value);
