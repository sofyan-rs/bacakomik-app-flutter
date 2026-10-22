import 'package:bacakomik_app/core/domain/entities/comic_details.dart';
import 'package:bacakomik_app/features/bookmark/domain/entities/bookmark.dart';
import 'package:bacakomik_app/features/history/domain/entities/read_history.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'sync_snapshot.freezed.dart';

/// The synced part of a library, on this device or in the cloud. Lists are
/// sorted by slug so equal libraries compare equal.
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
  }) = _SyncSnapshot;

  /// Merges two libraries. Per slug the newest version wins: a bookmark by
  /// [Bookmark.updatedDate], a history entry by [ReadHistory.readDate]. An
  /// entry deleted at or after that time is dropped. Deletions older than
  /// [keepDeletionsSince] are forgotten. On equal dates a migrated copy
  /// (with [ComicDetails.source]) wins over one stored before the switch.
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

    final bookmarks = _newestBySlug(
      [...a.bookmarks, ...b.bookmarks],
      slugOf: (b) => b.slug,
      dateOf: (b) => b.updatedDate,
      detailsOf: (b) => b.comicDetails,
      deleted: deletedBookmarks,
    );
    final history = _newestBySlug(
      [...a.history, ...b.history],
      slugOf: (h) => h.slug,
      dateOf: (h) => h.readDate,
      detailsOf: (h) => h.comicDetails,
      deleted: deletedHistory,
    );

    return SyncSnapshot(
      bookmarks: bookmarks,
      history: history,
      deletedBookmarks: deletedBookmarks,
      deletedHistory: deletedHistory,
    );
  }

  /// Same library, with lists sorted by slug.
  SyncSnapshot sorted() => copyWith(
    bookmarks: [...bookmarks]..sort((a, b) => a.slug.compareTo(b.slug)),
    history: [...history]..sort((a, b) => a.slug.compareTo(b.slug)),
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

List<T> _newestBySlug<T>(
  List<T> items, {
  required String Function(T) slugOf,
  required DateTime Function(T) dateOf,
  required ComicDetails Function(T) detailsOf,
  required Map<String, DateTime> deleted,
}) {
  final newest = <String, T>{};
  for (final item in items) {
    final current = newest[slugOf(item)];
    if (current == null ||
        dateOf(item).isAfter(dateOf(current)) ||
        (dateOf(item) == dateOf(current) &&
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
