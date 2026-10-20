// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'downloaded_chapter_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DownloadedChapterModel _$DownloadedChapterModelFromJson(
  Map<String, dynamic> json,
) => DownloadedChapterModel(
  slug: json['slug'] as String,
  comicSlug: json['comicSlug'] as String,
  chapterNumber: json['chapterNumber'] as String,
  addedAt: const EpochMillisConverter().fromJson(
    (json['addedAt'] as num).toInt(),
  ),
  status:
      $enumDecodeNullable(
        _$DownloadStatusEnumMap,
        json['status'],
        unknownValue: DownloadStatus.failed,
      ) ??
      DownloadStatus.queued,
  chapterTitle: json['chapterTitle'] as String?,
  previousChapterSlug: json['previousChapterSlug'] as String?,
  nextChapterSlug: json['nextChapterSlug'] as String?,
  pageCount: (json['pageCount'] as num?)?.toInt() ?? 0,
  pages:
      (json['pages'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  sizeBytes: (json['sizeBytes'] as num?)?.toInt() ?? 0,
  downloadedAt: _$JsonConverterFromJson<int, DateTime>(
    json['downloadedAt'],
    const EpochMillisConverter().fromJson,
  ),
);

Map<String, dynamic> _$DownloadedChapterModelToJson(
  DownloadedChapterModel instance,
) => <String, dynamic>{
  'slug': instance.slug,
  'comicSlug': instance.comicSlug,
  'chapterNumber': instance.chapterNumber,
  'addedAt': const EpochMillisConverter().toJson(instance.addedAt),
  'status': _$DownloadStatusEnumMap[instance.status]!,
  'chapterTitle': instance.chapterTitle,
  'previousChapterSlug': instance.previousChapterSlug,
  'nextChapterSlug': instance.nextChapterSlug,
  'pageCount': instance.pageCount,
  'pages': instance.pages,
  'sizeBytes': instance.sizeBytes,
  'downloadedAt': _$JsonConverterToJson<int, DateTime>(
    instance.downloadedAt,
    const EpochMillisConverter().toJson,
  ),
};

const _$DownloadStatusEnumMap = {
  DownloadStatus.queued: 'queued',
  DownloadStatus.downloading: 'downloading',
  DownloadStatus.completed: 'completed',
  DownloadStatus.failed: 'failed',
};

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) => json == null ? null : fromJson(json as Json);

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) => value == null ? null : toJson(value);

DownloadComicModel _$DownloadComicModelFromJson(Map<String, dynamic> json) =>
    DownloadComicModel(
      slug: json['slug'] as String,
      comicDetails: ComicDetailsModel.fromJson(
        json['comicDetails'] as Map<String, dynamic>,
      ),
      cover: json['cover'] as String?,
    );

Map<String, dynamic> _$DownloadComicModelToJson(DownloadComicModel instance) =>
    <String, dynamic>{
      'slug': instance.slug,
      'comicDetails': instance.comicDetails.toJson(),
      'cover': instance.cover,
    };
