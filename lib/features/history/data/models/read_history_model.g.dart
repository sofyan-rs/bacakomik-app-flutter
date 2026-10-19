// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'read_history_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReadHistoryModel _$ReadHistoryModelFromJson(Map<String, dynamic> json) =>
    ReadHistoryModel(
      slug: json['slug'] as String,
      chapterNumber: json['chapterNumber'] as String,
      readDate: const EpochMillisConverter().fromJson(
        (json['readDate'] as num).toInt(),
      ),
      comicDetails: ComicDetailsModel.fromJson(
        json['comicDetails'] as Map<String, dynamic>,
      ),
      comicSlug: json['comicSlug'] as String,
    );

Map<String, dynamic> _$ReadHistoryModelToJson(ReadHistoryModel instance) =>
    <String, dynamic>{
      'slug': instance.slug,
      'chapterNumber': instance.chapterNumber,
      'readDate': const EpochMillisConverter().toJson(instance.readDate),
      'comicDetails': instance.comicDetails.toJson(),
      'comicSlug': instance.comicSlug,
    };
