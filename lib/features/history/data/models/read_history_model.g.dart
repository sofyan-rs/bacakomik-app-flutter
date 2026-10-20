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
      comicSlug: json['comicSlug'] as String,
      page: (json['page'] as num?)?.toInt(),
      pageCount: (json['pageCount'] as num?)?.toInt(),
    );

Map<String, dynamic> _$ReadHistoryModelToJson(ReadHistoryModel instance) =>
    <String, dynamic>{
      'slug': instance.slug,
      'chapterNumber': instance.chapterNumber,
      'readDate': const EpochMillisConverter().toJson(instance.readDate),
      'comicSlug': instance.comicSlug,
      'page': ?instance.page,
      'pageCount': ?instance.pageCount,
    };

HistoryComicModel _$HistoryComicModelFromJson(Map<String, dynamic> json) =>
    HistoryComicModel(
      slug: json['slug'] as String,
      comicDetails: ComicDetailsModel.fromJson(
        json['comicDetails'] as Map<String, dynamic>,
      ),
    );

Map<String, dynamic> _$HistoryComicModelToJson(HistoryComicModel instance) =>
    <String, dynamic>{
      'slug': instance.slug,
      'comicDetails': instance.comicDetails.toJson(),
    };
