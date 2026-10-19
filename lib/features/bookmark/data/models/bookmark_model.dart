import 'package:bacakomik_app/core/data/models/comic_details_model.dart';
import 'package:bacakomik_app/features/bookmark/domain/entities/bookmark.dart';
import 'package:json_annotation/json_annotation.dart';

part 'bookmark_model.g.dart';

/// Stored bookmark. Same JSON shape as earlier app versions and backups.
@JsonSerializable()
class BookmarkModel {
  const BookmarkModel({
    required this.slug,
    required this.comicDetails,
    required this.updatedDate,
  });

  factory BookmarkModel.fromEntity(Bookmark e) => BookmarkModel(
        slug: e.slug,
        comicDetails: ComicDetailsModel.fromEntity(e.comicDetails),
        updatedDate: e.updatedDate,
      );

  factory BookmarkModel.fromJson(Map<String, dynamic> json) =>
      _$BookmarkModelFromJson(json);

  final String slug;
  final ComicDetailsModel comicDetails;
  @EpochMillisConverter()
  final DateTime updatedDate;

  Map<String, dynamic> toJson() => _$BookmarkModelToJson(this);

  Bookmark toEntity() => Bookmark(
        slug: slug,
        comicDetails: comicDetails.toEntity(),
        updatedDate: updatedDate,
      );
}
