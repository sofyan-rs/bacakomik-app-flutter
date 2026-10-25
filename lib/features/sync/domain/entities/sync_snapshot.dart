import 'package:bacakomik_app/core/domain/entities/comic_details.dart';
import 'package:bacakomik_app/features/bookmark/domain/entities/bookmark.dart';
import 'package:bacakomik_app/features/category/domain/entities/category.dart';
import 'package:bacakomik_app/features/history/domain/entities/read_history.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'sync_snapshot.freezed.dart';

/// The synced part of a library, on this device or in the cloud. Lists are
/// sorted by slug (categories by id) so equal libraries compare equal.
@freezed
abstract class SyncSnapshot with _$SyncSnapshot {
  const SyncSnapshot._();

  const factory SyncSnapshot({
    @Default([]) List<Bookmark> bookmarks,
    @Default([]) List<ReadHistory> history,

    /// Deletion time per bookmark slug.
    @Default({}) Map<String, DateTime> deletedBookmarks,

    /// Deletion time per chapter slug.
    @Default({}) Map<String, DateTime> deletedHistory,
    @Default([]) List<LibraryCategory> categories,
    @Default([]) List<ComicCategories> comicCategories,

    /// Deletion time per category id.
    @Default({}) Map<String, DateTime> deletedCategories,
  }) = _SyncSnapshot;

  /// Merges two libraries. Per slug the newest version wins: a bookmark by
  /// [Bookmark.updatedDate], a history entry by [ReadHistory.readDate], a
  /// category (per id) and a comic's categories by their `updatedDate`. An
  /// entry deleted at or after that time is dropped. A side without the
  /// category fields (an app version before categories) keeps the other
  /// side's. Deletions older than
  /// [keepDeletionsSince] are forgotten. On equal dates a migrated copy
  /// (with [ComicDetails.source]) wins over one stored before the switch.
  /// A winning bookmark without [Bookmark.addedDate] (saved by an app
  /// version before it) takes the other side's.
  factory SyncSnapshot.merge(
    SyncSnapshot a,
    SyncSnapshot b, {
    required DateTime keepDeletionsSince,
  }) {
    final deletedBookmarks = _newestDates(
      a.deletedBookmarks,
      b.deletedBookmarks,
      keepDeletionsSince,
    );
    final deletedHistory = _newestDates(
      a.deletedHistory,
      b.deletedHistory,
      keepDeletionsSince,
    );
    final deletedCategories = _newestDates(
      a.deletedCategories,
      b.deletedCategories,
      keepDeletionsSince,
    );

    final bookmarks = _keepAddedDates(
      _newestBySlug(
        [...a.bookmarks, ...b.bookmarks],
        slugOf: (b) => b.slug,
        dateOf: (b) => b.updatedDate,
        detailsOf: (b) => b.comicDetails,
        deleted: deletedBookmarks,
      ),
      [...a.bookmarks, ...b.bookmarks],
    );
    final history = _newestBySlug(
      [...a.history, ...b.history],
      slugOf: (h) => h.slug,
      dateOf: (h) => h.readDate,
      detailsOf: (h) => h.comicDetails,
      deleted: deletedHistory,
    );

    final categories = _newestBySlug(
      [...a.categories, ...b.categories],
      slugOf: (c) => c.id,
      dateOf: (c) => c.updatedDate,
      deleted: deletedCategories,
    );
    final comicCategories = _newestBySlug(
      [...a.comicCategories, ...b.comicCategories],
      slugOf: (c) => c.slug,
      dateOf: (c) => c.updatedDate,
      deleted: const {},
    );

    return SyncSnapshot(
      bookmarks: bookmarks,
      history: history,
      deletedBookmarks: deletedBookmarks,
      deletedHistory: deletedHistory,
      categories: categories,
      comicCategories: comicCategories,
      deletedCategories: deletedCategories,
    );
  }

  /// Same library, with lists sorted by slug.
  SyncSnapshot sorted() => copyWith(
    bookmarks: [...bookmarks]..sort((a, b) => a.slug.compareTo(b.slug)),
    history: [...history]..sort((a, b) => a.slug.compareTo(b.slug)),
    categories: [...categories]..sort((a, b) => a.id.compareTo(b.id)),
    comicCategories: [...comicCategories]
      ..sort((a, b) => a.slug.compareTo(b.slug)),
  );

  /// Same entries and deletions, ignoring list order.
  bool sameAs(SyncSnapshot other) => sorted() == other.sorted();
}

Map<String, DateTime> _newestDates(
  Map<String, DateTime> a,
  Map<String, DateTime> b,
  DateTime keepSince,
) {
  final result = <String, DateTime>{};
  for (final MapEntry(:key, :value) in [...a.entries, ...b.entries]) {
    if (value.isBefore(keepSince)) continue;
    final current = result[key];
    if (current == null || value.isAfter(current)) result[key] = value;
  }
  return result;
}

/// [merged] with each missing [Bookmark.addedDate] taken from another copy
/// of the same slug in [all].
List<Bookmark> _keepAddedDates(List<Bookmark> merged, List<Bookmark> all) {
  final added = {for (final b in all) b.slug: ?b.addedDate};
  return [
    for (final b in merged)
      b.addedDate == null && added[b.slug] != null
          ? b.copyWith(addedDate: added[b.slug])
          : b,
  ];
}

List<T> _newestBySlug<T>(
  List<T> items, {
  required String Function(T) slugOf,
  required DateTime Function(T) dateOf,
  required Map<String, DateTime> deleted,

  /// For comics: on equal dates the copy with a source wins.
  ComicDetails Function(T)? detailsOf,
}) {
  final newest = <String, T>{};
  for (final item in items) {
    final current = newest[slugOf(item)];
    if (current == null ||
        dateOf(item).isAfter(dateOf(current)) ||
        (detailsOf != null &&
            dateOf(item) == dateOf(current) &&
            detailsOf(current).source == null &&
            detailsOf(item).source != null)) {
      newest[slugOf(item)] = item;
    }
  }
  newest.removeWhere(
    (slug, item) => !(deleted[slug]?.isBefore(dateOf(item)) ?? true),
  );
  return newest.values.toList()..sort((a, b) => slugOf(a).compareTo(slugOf(b)));
}
