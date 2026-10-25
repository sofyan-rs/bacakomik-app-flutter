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

    /// When a deleted bookmark was saved again, per slug ([merge]).
    @Default({}) Map<String, DateTime> savedBookmarks,

    /// When a deleted history entry was saved again, per chapter slug.
    @Default({}) Map<String, DateTime> savedHistory,

    /// When a deleted category was saved again, per id.
    @Default({}) Map<String, DateTime> savedCategories,
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
  ///
  /// An entry saved again after it was deleted ([savedBookmarks] and the
  /// like: a restored backup or an import, whose entries keep their older
  /// dates) cancels that deletion, so the deletion no longer drops it. The
  /// save times are kept as long as deletions, so a deletion still on a
  /// device that was offline is cancelled too.
  factory SyncSnapshot.merge(
    SyncSnapshot a,
    SyncSnapshot b, {
    required DateTime keepDeletionsSince,
  }) {
    final savedBookmarks = _newestDates(
      a.savedBookmarks,
      b.savedBookmarks,
      keepDeletionsSince,
    );
    final savedHistory = _newestDates(
      a.savedHistory,
      b.savedHistory,
      keepDeletionsSince,
    );
    final savedCategories = _newestDates(
      a.savedCategories,
      b.savedCategories,
      keepDeletionsSince,
    );
    final deletedBookmarks = _withoutSavedAgain(
      _newestDates(a.deletedBookmarks, b.deletedBookmarks, keepDeletionsSince),
      savedBookmarks,
    );
    final deletedHistory = _withoutSavedAgain(
      _newestDates(a.deletedHistory, b.deletedHistory, keepDeletionsSince),
      savedHistory,
    );
    final deletedCategories = _withoutSavedAgain(
      _newestDates(
        a.deletedCategories,
        b.deletedCategories,
        keepDeletionsSince,
      ),
      savedCategories,
    );

    final bookmarks = _keepAddedDates(
      _newestBySlug(
        a.bookmarks,
        b.bookmarks,
        slugOf: _bookmarkSlug,
        dateOf: (b) => b.updatedDate,
        detailsOf: (b) => b.comicDetails,
        deleted: deletedBookmarks,
      ),
      [...a.bookmarks, ...b.bookmarks],
    );
    final history = _newestBySlug(
      a.history,
      b.history,
      slugOf: _historySlug,
      dateOf: (h) => h.readDate,
      detailsOf: (h) => h.comicDetails,
      deleted: deletedHistory,
    );

    final categories = _newestBySlug(
      a.categories,
      b.categories,
      slugOf: _categoryId,
      dateOf: (c) => c.updatedDate,
      deleted: deletedCategories,
    );
    final comicCategories = _newestBySlug(
      a.comicCategories,
      b.comicCategories,
      slugOf: _comicCategoriesSlug,
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
      savedBookmarks: savedBookmarks,
      savedHistory: savedHistory,
      savedCategories: savedCategories,
    );
  }

  /// Same library, with lists sorted by slug. A snapshot already in order
  /// is returned as is.
  SyncSnapshot sorted() {
    if (_inOrder(bookmarks, _bookmarkSlug) &&
        _inOrder(history, _historySlug) &&
        _inOrder(categories, _categoryId) &&
        _inOrder(comicCategories, _comicCategoriesSlug)) {
      return this;
    }
    return copyWith(
      bookmarks: _bySlug(bookmarks, _bookmarkSlug),
      history: _bySlug(history, _historySlug),
      categories: _bySlug(categories, _categoryId),
      comicCategories: _bySlug(comicCategories, _comicCategoriesSlug),
    );
  }

  /// Same entries and deletions, ignoring list order: what
  /// `sorted() == other.sorted()` gives, without comparing a comic's
  /// details again for each of its history entries. Entries of one comic
  /// share one details object (the repositories and the sync file store
  /// details once per comic), so each pair of details objects is compared
  /// deeply once and remembered; every other field is compared by the
  /// entities' own `==`.
  bool sameAs(SyncSnapshot other) {
    final details = _DetailsComparison();
    bool sameComic<T>(
      T x,
      T y,
      ComicDetails Function(T) detailsOf,
      T Function(T, ComicDetails) withDetails,
    ) {
      final (dx, dy) = (detailsOf(x), detailsOf(y));
      if (identical(dx, dy)) return x == y;
      // Equal details: compare the rest with [y]'s details swapped in, so
      // `==` finds them identical and does not walk the chapters again.
      return details.same(dx, dy) && withDetails(x, dy) == y;
    }

    return _sameDates(deletedBookmarks, other.deletedBookmarks) &&
        _sameDates(deletedHistory, other.deletedHistory) &&
        _sameDates(deletedCategories, other.deletedCategories) &&
        _sameDates(savedBookmarks, other.savedBookmarks) &&
        _sameDates(savedHistory, other.savedHistory) &&
        _sameDates(savedCategories, other.savedCategories) &&
        _sameLists(
          categories,
          other.categories,
          _categoryId,
          (x, y) => x == y,
        ) &&
        _sameLists(
          comicCategories,
          other.comicCategories,
          _comicCategoriesSlug,
          (x, y) => x == y,
        ) &&
        _sameLists(
          bookmarks,
          other.bookmarks,
          _bookmarkSlug,
          (x, y) => sameComic(
            x,
            y,
            (b) => b.comicDetails,
            (b, d) => b.copyWith(comicDetails: d),
          ),
        ) &&
        _sameLists(
          history,
          other.history,
          _historySlug,
          (x, y) => sameComic(
            x,
            y,
            (h) => h.comicDetails,
            (h, d) => h.copyWith(comicDetails: d),
          ),
        );
  }
}

String _bookmarkSlug(Bookmark b) => b.slug;
String _historySlug(ReadHistory h) => h.slug;
String _categoryId(LibraryCategory c) => c.id;
String _comicCategoriesSlug(ComicCategories c) => c.slug;

/// Whether [items] are sorted by [keyOf] (one pass).
bool _inOrder<T>(List<T> items, String Function(T) keyOf) {
  for (var i = 1; i < items.length; i++) {
    if (keyOf(items[i - 1]).compareTo(keyOf(items[i])) > 0) return false;
  }
  return true;
}

/// Sorted by [keyOf] with no key twice.
bool _strictlyInOrder<T>(List<T> items, String Function(T) keyOf) {
  for (var i = 1; i < items.length; i++) {
    if (keyOf(items[i - 1]).compareTo(keyOf(items[i])) >= 0) return false;
  }
  return true;
}

/// [items] sorted by [keyOf]; the list itself when already in order.
List<T> _bySlug<T>(List<T> items, String Function(T) keyOf) =>
    _inOrder(items, keyOf)
    ? items
    : ([...items]..sort((a, b) => keyOf(a).compareTo(keyOf(b))));

bool _sameDates(Map<String, DateTime> a, Map<String, DateTime> b) {
  if (a.length != b.length) return false;
  for (final MapEntry(:key, :value) in a.entries) {
    if (b[key] != value) return false;
  }
  return true;
}

/// [a] and [b] hold the same items once sorted by [keyOf].
bool _sameLists<T>(
  List<T> a,
  List<T> b,
  String Function(T) keyOf,
  bool Function(T, T) same,
) {
  if (a.length != b.length) return false;
  final (x, y) = (_bySlug(a, keyOf), _bySlug(b, keyOf));
  for (var i = 0; i < x.length; i++) {
    if (!identical(x[i], y[i]) && !same(x[i], y[i])) return false;
  }
  return true;
}

/// Compares details objects deeply once per pair, by identity.
class _DetailsComparison {
  final _known = Map<ComicDetails, Map<ComicDetails, bool>>.identity();

  bool same(ComicDetails a, ComicDetails b) => _known
      .putIfAbsent(a, Map<ComicDetails, bool>.identity)
      .putIfAbsent(b, () => a == b);
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

/// [deleted] minus the deletions [saved] has a later save for.
Map<String, DateTime> _withoutSavedAgain(
  Map<String, DateTime> deleted,
  Map<String, DateTime> saved,
) {
  if (saved.isEmpty) return deleted;
  return {
    for (final MapEntry(:key, :value) in deleted.entries)
      if (!(saved[key]?.isAfter(value) ?? false)) key: value,
  };
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

/// The newest item per slug of [a] then [b], minus deleted ones, sorted by
/// slug. When both lists are sorted by slug without repeats (as snapshots
/// read from a device or the sync file are), they are merged in one pass
/// instead of hashed and sorted; the result is the same.
List<T> _newestBySlug<T>(
  List<T> a,
  List<T> b, {
  required String Function(T) slugOf,
  required DateTime Function(T) dateOf,
  required Map<String, DateTime> deleted,

  /// For comics: on equal dates the copy with a source wins.
  ComicDetails Function(T)? detailsOf,
}) {
  // Whether [item] replaces [current], which came before it.
  bool replaces(T current, T item) =>
      dateOf(item).isAfter(dateOf(current)) ||
      (detailsOf != null &&
          dateOf(item) == dateOf(current) &&
          detailsOf(current).source == null &&
          detailsOf(item).source != null);

  bool kept(T item) => deleted[slugOf(item)]?.isBefore(dateOf(item)) ?? true;

  if (_strictlyInOrder(a, slugOf) && _strictlyInOrder(b, slugOf)) {
    final result = <T>[];
    void add(T item) {
      if (kept(item)) result.add(item);
    }

    var (i, j) = (0, 0);
    while (i < a.length && j < b.length) {
      final order = slugOf(a[i]).compareTo(slugOf(b[j]));
      if (order < 0) {
        add(a[i++]);
      } else if (order > 0) {
        add(b[j++]);
      } else {
        final (x, y) = (a[i++], b[j++]);
        add(replaces(x, y) ? y : x);
      }
    }
    a.skip(i).forEach(add);
    b.skip(j).forEach(add);
    return result;
  }

  final newest = <String, T>{};
  for (final item in [...a, ...b]) {
    final current = newest[slugOf(item)];
    if (current == null || replaces(current, item)) {
      newest[slugOf(item)] = item;
    }
  }
  newest.removeWhere((slug, item) => !kept(item));
  return newest.values.toList()..sort((a, b) => slugOf(a).compareTo(slugOf(b)));
}
