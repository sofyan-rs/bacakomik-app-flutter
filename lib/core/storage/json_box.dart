import 'dart:convert';

import 'package:bacakomik_app/core/storage/box_recovery.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive.dart';

/// Typed view over a `Box<String>` whose values are JSON-encoded objects.
class JsonBox<T> {
  JsonBox(
    this._box, {
    required this.fromJson,
    required this.toJson,
    required this.keyOf,
  });

  final Box<String> _box;
  final T Function(Map<String, dynamic> json) fromJson;
  final Map<String, dynamic> Function(T value) toJson;
  final String Function(T value) keyOf;

  /// All stored values. Entries that no longer parse are skipped so one bad
  /// record cannot hide the rest.
  List<T> values() {
    final result = <T>[];
    for (final key in _box.keys) {
      final raw = _box.get(key);
      if (raw == null) continue;
      try {
        result.add(decode(raw));
      } catch (e) {
        debugPrint('Skipping unreadable ${_box.name} entry $key: $e');
      }
    }
    return result;
  }

  T? get(String key) {
    final raw = _box.get(key);
    return raw == null ? null : decode(raw);
  }

  /// A value whose key Hive cannot store ([isValidHiveKey]) is skipped:
  /// writing it would corrupt the box file.
  Future<void> put(T value) => putAll([value]);

  Future<void> putAll(Iterable<T> values) => _box.putAll({
    for (final v in values)
      if (_storable(keyOf(v))) keyOf(v): encode(v),
  });

  bool _storable(String key) {
    if (isValidHiveKey(key)) return true;
    debugPrint('Skipping ${_box.name} entry with an unstorable key: $key');
    return false;
  }

  Future<void> deleteAll(Iterable<String> keys) => _box.deleteAll(keys);

  Future<void> clear() => _box.clear();

  T decode(String raw) => fromJson(jsonDecode(raw) as Map<String, dynamic>);

  String encode(T value) => jsonEncode(toJson(value));
}
