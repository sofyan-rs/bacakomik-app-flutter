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
    );

Map<String, dynamic> _$BookmarkModelToJson(BookmarkModel instance) =>
    <String, dynamic>{
      'slug': instance.slug,
      'comicDetails': instance.comicDetails.toJson(),
      'updatedDate': const EpochMillisConverter().toJson(instance.updatedDate),
    };
