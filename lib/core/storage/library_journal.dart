import 'dart:async';

import 'package:bacakomik_app/core/storage/hive_boxes.dart';
import 'package:bacakomik_app/core/utils/clock.dart';
import 'package:bacakomik_app/core/storage/box_recovery.dart';
import 'package:hive_ce/hive.dart';
import 'package:injectable/injectable.dart';

enum LibraryKind { bookmark, history, category, comicCategories }

/// Records library edits for sync: when each bookmark, history entry or
/// category was deleted, when a deleted one was saved again, and a [changes]
/// event after every local save or delete.
///
/// Deletion times are stored as epoch milliseconds keyed by `kind:slug`;
/// save-again times keyed by `saved:kind:slug`.
@lazySingleton
class LibraryJournal {
  LibraryJournal(@Named(HiveBoxes.libraryDeletions) this._box, this._clock);

  final Box<String> _box;
  final Clock _clock;
  final _changes = StreamController<void>.broadcast(sync: true);

  /// Fires after the user's library was edited on this device. Writes made by
  /// sync itself do not fire.
  Stream<void> get changes => _changes.stream;

  /// Deletion time per slug.
  Map<String, DateTime> deleted(LibraryKind kind) => _dates(_prefix(kind));

  /// When each entry that had a deletion recorded was saved again, per slug.
  /// Sync keeps the entry over that (older) deletion, whatever the entry's
  /// own date: a restored backup or an import keeps its old dates.
  Map<String, DateTime> saved(LibraryKind kind) => _dates(_savedPrefix(kind));

  Map<String, DateTime> _dates(String prefix) {
    return {
      for (final key in _box.keys.cast<String>())
        if (key.startsWith(prefix))
          if (int.tryParse(_box.get(key) ?? '') case final ms?)
            key.substring(prefix.length): DateTime.fromMillisecondsSinceEpoch(
              ms,
            ),
    };
  }

  Future<void> recordDeleted(LibraryKind kind, Iterable<String> slugs) async {
    final now = '${_clock.now().millisecondsSinceEpoch}';
    await _box.putAll({
      for (final slug in slugs)
        if (isValidHiveKey(_key(kind, slug))) _key(kind, slug): now,
    });
    _changes.add(null);
  }

  /// A saved entry is no longer deleted; one that was gets its save time
  /// recorded ([saved]). A [quiet] save (the reader keeping its page) fires
  /// no [changes]: whoever saves quietly makes a normal save later (the
  /// reader does when it closes or the app pauses), so sync still picks the
  /// edit up without syncing on every page.
  Future<void> recordSaved(
    LibraryKind kind,
    Iterable<String> slugs, {
    bool quiet = false,
  }) async {
    final keys = slugs.map((slug) => _key(kind, slug)).where(isValidHiveKey);
    final deleted = [
      for (final key in keys)
        if (_box.containsKey(key)) key,
    ];
    if (deleted.isNotEmpty) {
      final now = '${_clock.now().millisecondsSinceEpoch}';
      await Future.wait([
        _box.putAll({
          for (final key in deleted)
            if ('$_savedTag$key' case final saved when isValidHiveKey(saved))
              saved: now,
        }),
        _box.deleteAll(deleted),
      ]);
    }
    if (!quiet) _changes.add(null);
  }

  /// Replaces every deletion of [kind], without firing [changes].
  Future<void> replaceDeleted(
    LibraryKind kind,
    Map<String, DateTime> deleted,
  ) => _replace(_prefix(kind), deleted, null);

  /// Makes the deletions and save-again times of [kind] those of a sync
  /// ([deleted], [saved]), without firing [changes]. With [since], what
  /// was read before the sync, a record that changed since then (an edit
  /// made during the sync) is left as it is, and so is one added since.
  Future<void> replaceSynced(
    LibraryKind kind, {
    required Map<String, DateTime> deleted,
    required Map<String, DateTime> saved,
    ({Map<String, DateTime> deleted, Map<String, DateTime> saved})? since,
  }) async {
    await _replace(_prefix(kind), deleted, since?.deleted);
    await _replace(_savedPrefix(kind), saved, since?.saved);
  }

  /// Makes the records under [prefix] hold [dates]; with [base], only those
  /// still as in [base] change. Decided synchronously, before the writes
  /// start, so no edit can come in between.
  Future<void> _replace(
    String prefix,
    Map<String, DateTime> dates,
    Map<String, DateTime>? base,
  ) async {
    String? stringOf(DateTime? date) =>
        date == null ? null : '${date.millisecondsSinceEpoch}';
    bool unchanged(String slug, String key) =>
        base == null || _box.get(key) == stringOf(base[slug]);

    final put = {
      for (final MapEntry(:key, :value) in dates.entries)
        if ('$prefix$key' case final k when isValidHiveKey(k))
          if (_box.get(k) != stringOf(value) && unchanged(key, k))
            k: stringOf(value)!,
    };
    final delete = [
      for (final k in _box.keys.cast<String>())
        if (k.startsWith(prefix))
          if (k.substring(prefix.length) case final slug
              when !dates.containsKey(slug) &&
                  (base == null || base.containsKey(slug)) &&
                  unchanged(slug, k))
            k,
    ];
    await Future.wait([_box.putAll(put), _box.deleteAll(delete)]);
  }

  static const _savedTag = 'saved:';

  static String _prefix(LibraryKind kind) => '${kind.name}:';

  static String _savedPrefix(LibraryKind kind) => '$_savedTag${kind.name}:';

  static String _key(LibraryKind kind, String slug) => '${_prefix(kind)}$slug';
}
