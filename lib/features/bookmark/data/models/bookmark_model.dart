import 'package:bacakomik_app/core/data/models/comic_details_model.dart';
import 'package:bacakomik_app/features/bookmark/domain/entities/bookmark.dart';
import 'package:json_annotation/json_annotation.dart';

part 'bookmark_model.g.dart';

/// Stored bookmark, also used in backup files.
@JsonSerializable()
class BookmarkModel {
  const BookmarkModel({
    required this.slug,
    required this.comicDetails,
    required this.updatedDate,
    this.addedDate,
    this.mergedKeys,
  });

  factory BookmarkModel.fromEntity(Bookmark e) => BookmarkModel(
    slug: e.slug,
    comicDetails: ComicDetailsModel.fromEntity(e.comicDetails),
    updatedDate: e.updatedDate,
    addedDate: e.addedDate,
    mergedKeys: e.mergedKeys.isEmpty ? null : e.mergedKeys,
  );

  factory BookmarkModel.fromJson(Map<String, dynamic> json) =>
      _$BookmarkModelFromJson(json);

  final String slug;
  final ComicDetailsModel comicDetails;
  @EpochMillisConverter()
  final DateTime updatedDate;

  /// Absent in bookmarks stored before it was kept; older app versions
  /// ignore it.
  @JsonKey(includeIfNull: false)
  @EpochMillisConverter()
  final DateTime? addedDate;

  /// Absent when the bookmark has one source; older app versions ignore
  /// it.
  @JsonKey(includeIfNull: false)
  final List<String>? mergedKeys;

  Map<String, dynamic> toJson() => _$BookmarkModelToJson(this);

  Bookmark toEntity() => Bookmark(
    slug: slug,
    comicDetails: comicDetails.toEntity(),
    updatedDate: updatedDate,
    addedDate: addedDate,
    mergedKeys: mergedKeys ?? const [],
  );
}
