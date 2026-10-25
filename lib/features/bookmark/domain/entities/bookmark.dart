import 'package:bacakomik_app/core/domain/entities/comic_details.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'bookmark.freezed.dart';

@freezed
abstract class Bookmark with _$Bookmark {
  const factory Bookmark({
    /// Series slug.
    required String slug,
    required ComicDetails comicDetails,

    /// Last time the bookmark was added or found new chapters.
    required DateTime updatedDate,

    /// When the comic was bookmarked. Null for bookmarks saved before this
    /// was stored; sorting uses [updatedDate] for them.
    DateTime? addedDate,
  }) = _Bookmark;
}

/// Repository order: newest [Bookmark.updatedDate] first, equal dates by
/// slug.
int compareBookmarksNewestFirst(Bookmark a, Bookmark b) {
  final byDate = b.updatedDate.compareTo(a.updatedDate);
  return byDate != 0 ? byDate : a.slug.compareTo(b.slug);
}
