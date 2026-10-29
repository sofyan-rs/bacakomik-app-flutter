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

    /// Series keys merged into this entry, [slug] among them, in the order
    /// chapters are taken from: each chapter number comes from the first
    /// that has it, and the details from the first. Empty when the entry
    /// has one source. See [sourceKeys].
    @Default(<String>[]) List<String> mergedKeys,

    /// A merged entry lists the chapters of every source, also the numbers
    /// several have, instead of one per number.
    @Default(false) bool keepDuplicates,
  }) = _Bookmark;

  const Bookmark._();

  /// The series keys the entry is read from, most wanted first.
  List<String> get sourceKeys => mergedKeys.isEmpty ? [slug] : mergedKeys;

  bool get isMerged => mergedKeys.length > 1;
}

/// Repository order: newest [Bookmark.updatedDate] first, equal dates by
/// slug.
int compareBookmarksNewestFirst(Bookmark a, Bookmark b) {
  final byDate = b.updatedDate.compareTo(a.updatedDate);
  return byDate != 0 ? byDate : a.slug.compareTo(b.slug);
}
