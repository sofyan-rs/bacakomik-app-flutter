import 'package:bacakomik_app/core/data/models/comic_details_model.dart';
import 'package:bacakomik_app/core/domain/entities/comic_details.dart';
import 'package:bacakomik_app/features/history/domain/entities/read_history.dart';
import 'package:json_annotation/json_annotation.dart';

part 'read_history_model.g.dart';

/// Stored history entry: one read chapter. The comic's details are stored
/// once per comic in [HistoryComicModel], not in every entry.
@JsonSerializable()
class ReadHistoryModel {
  const ReadHistoryModel({
    required this.slug,
    required this.chapterNumber,
    required this.readDate,
    required this.comicSlug,
  });

  factory ReadHistoryModel.fromEntity(ReadHistory e) => ReadHistoryModel(
    slug: e.slug,
    chapterNumber: e.chapterNumber,
    readDate: e.readDate,
    comicSlug: e.comicSlug,
  );

  factory ReadHistoryModel.fromJson(Map<String, dynamic> json) =>
      _$ReadHistoryModelFromJson(json);

  /// Chapter slug (`seriesSlug/number`).
  final String slug;
  final String chapterNumber;
  @EpochMillisConverter()
  final DateTime readDate;
  final String comicSlug;

  Map<String, dynamic> toJson() => _$ReadHistoryModelToJson(this);

  ReadHistory toEntity(ComicDetails comicDetails) => ReadHistory(
    slug: slug,
    chapterNumber: chapterNumber,
    readDate: readDate,
    comicDetails: comicDetails,
    comicSlug: comicSlug,
  );
}

/// Details of a comic that has history entries, keyed by the series slug.
@JsonSerializable()
class HistoryComicModel {
  const HistoryComicModel({required this.slug, required this.comicDetails});

  factory HistoryComicModel.fromJson(Map<String, dynamic> json) =>
      _$HistoryComicModelFromJson(json);

  /// Series slug.
  final String slug;
  final ComicDetailsModel comicDetails;

  Map<String, dynamic> toJson() => _$HistoryComicModelToJson(this);
}
