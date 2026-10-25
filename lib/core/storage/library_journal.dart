import 'dart:async';

import 'package:bacakomik_app/core/storage/hive_boxes.dart';
import 'package:bacakomik_app/core/utils/clock.dart';
import 'package:bacakomik_app/core/storage/box_recovery.dart';
import 'package:hive_ce/hive.dart';
import 'package:injectable/injectable.dart';

enum LibraryKind { bookmark, history, category, comicCategories }

/// Records library edits for sync: when each bookmark, history entry or
/// category was deleted, and a [changes] event after every local save or delete.
///
/// Deletion times are stored as epoch milliseconds keyed by `kind:slug`.
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
  Map<String, DateTime> deleted(LibraryKind kind) {
    final prefix = '${kind.name}:';
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

  /// A saved entry is no longer deleted. A [quiet] save (the reader keeping
  /// its page) fires no [changes]: whoever saves quietly makes a normal save
  /// later (the reader does when it closes or the app pauses), so sync still
  /// picks the edit up without syncing on every page.
  Future<void> recordSaved(
    LibraryKind kind,
    Iterable<String> slugs, {
    bool quiet = false,
  }) async {
    await _box.deleteAll(
      slugs.map((slug) => _key(kind, slug)).where(isValidHiveKey),
    );
    if (!quiet) _changes.add(null);
  }

  /// Replaces every deletion of [kind], without firing [changes].
  Future<void> replaceDeleted(
    LibraryKind kind,
    Map<String, DateTime> deleted,
  ) async {
    final prefix = '${kind.name}:';
    await _box.deleteAll(
      _box.keys.cast<String>().where((k) => k.startsWith(prefix)).toList(),
    );
    await _box.putAll({
      for (final MapEntry(:key, :value) in deleted.entries)
        if (isValidHiveKey(_key(kind, key)))
          _key(kind, key): '${value.millisecondsSinceEpoch}',
    });
  }

  static String _key(LibraryKind kind, String slug) => '${kind.name}:$slug';
}
