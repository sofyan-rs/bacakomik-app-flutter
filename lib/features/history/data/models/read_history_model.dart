import 'package:bacakomik_app/core/data/models/comic_details_model.dart';
import 'package:bacakomik_app/features/history/domain/entities/read_history.dart';
import 'package:json_annotation/json_annotation.dart';

part 'read_history_model.g.dart';

/// Stored history entry. Same JSON shape as earlier app versions and backups.
@JsonSerializable()
class ReadHistoryModel {
  const ReadHistoryModel({
    required this.slug,
    required this.chapterNumber,
    required this.readDate,
    required this.comicDetails,
    required this.comicSlug,
  });

  factory ReadHistoryModel.fromEntity(ReadHistory e) => ReadHistoryModel(
        slug: e.slug,
        chapterNumber: e.chapterNumber,
        readDate: e.readDate,
        comicDetails: ComicDetailsModel.fromEntity(e.comicDetails),
        comicSlug: e.comicSlug,
      );

  factory ReadHistoryModel.fromJson(Map<String, dynamic> json) =>
      _$ReadHistoryModelFromJson(json);

  final String slug;
  final String chapterNumber;
  @EpochMillisConverter()
  final DateTime readDate;
  final ComicDetailsModel comicDetails;
  final String comicSlug;

  Map<String, dynamic> toJson() => _$ReadHistoryModelToJson(this);

  ReadHistory toEntity() => ReadHistory(
        slug: slug,
        chapterNumber: chapterNumber,
        readDate: readDate,
        comicDetails: comicDetails.toEntity(),
        comicSlug: comicSlug,
      );
}
