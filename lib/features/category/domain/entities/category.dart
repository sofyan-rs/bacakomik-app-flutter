import 'package:freezed_annotation/freezed_annotation.dart';

part 'category.freezed.dart';

/// A user-made bookmark category, e.g. "Weekly" or "Favorites".
@freezed
abstract class LibraryCategory with _$LibraryCategory {
  const factory LibraryCategory({
    /// Random id; stays the same when the category is renamed.
    required String id,
    required String name,

    /// Position among the categories, lowest first.
    required int order,

    /// Last time it was created, renamed or moved; the newest wins in sync.
    required DateTime updatedDate,
  }) = _LibraryCategory;
}

/// The categories one bookmarked comic is in. Stored apart from the
/// bookmark so app versions without categories cannot overwrite them.
@freezed
abstract class ComicCategories with _$ComicCategories {
  const factory ComicCategories({
    /// Series key, as in [Bookmark.slug].
    required String slug,

    /// [LibraryCategory.id]s; empty for none.
    required List<String> categoryIds,

    /// Last time the categories were set; the newest wins in sync.
    required DateTime updatedDate,
  }) = _ComicCategories;
}
