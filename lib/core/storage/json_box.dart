import 'dart:convert';

import 'package:bacakomik_app/core/storage/box_recovery.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive.dart';

/// Stored JSON strings by key, for work that should not decode every
/// record on the UI isolate (sync encodes and decodes them in the
/// background).
abstract interface class RawJsonStore {
  /// Every stored key, without decoding anything.
  Iterable<String> get keys;

  /// Every stored JSON string by key.
  Map<String, String> readRaw();

  /// Makes the box hold exactly [values]: writes the ones whose stored JSON
  /// differs and deletes keys not in [values]. Keys Hive cannot store are
  /// skipped ([isValidHiveKey]).
  Future<void> replaceRaw(Map<String, String> values);
}

/// Typed view over a `Box<String>` whose values are JSON-encoded objects.
class JsonBox<T> implements RawJsonStore {
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

  /// The stored JSON of [key], undecoded.
  String? raw(String key) => _box.get(key);

  @override
  Iterable<String> get keys => _box.keys.cast<String>();

  @override
  Map<String, String> readRaw() => {
    for (final key in keys) key: ?_box.get(key),
  };

  @override
  Future<void> replaceRaw(Map<String, String> values) async {
    await _box.putAll({
      for (final MapEntry(:key, :value) in values.entries)
        if (_box.get(key) != value && _storable(key)) key: value,
    });
    await _box.deleteAll([
      for (final key in keys)
        if (!values.containsKey(key)) key,
    ]);
  }

  /// A value whose key Hive cannot store ([isValidHiveKey]) is skipped:
  /// writing it would corrupt the box file.
  Future<void> put(T value) => putAll([value]);

  Future<void> putAll(Iterable<T> values) => _box.putAll({
    for (final v in values)
      if (_storable(keyOf(v))) keyOf(v): encode(v),
  });

  /// Like [putAll], but leaves records whose stored JSON is already the
  /// same, so an unchanged record costs an encode and no disk write.
  Future<void> putAllChanged(Iterable<T> values) => _box.putAll({
    for (final v in values)
      if (encode(v) case final json when _box.get(keyOf(v)) != json)
        if (_storable(keyOf(v))) keyOf(v): json,
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
