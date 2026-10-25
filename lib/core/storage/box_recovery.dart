import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive.dart';

/// Folder Hive was initialised with; set next to `Hive.init`.
String? hiveDirectory;

/// Hive keys are stored with a one-byte length: longer or non-ASCII keys
/// corrupt the box file. [JsonBox] skips them.
bool isValidHiveKey(String key) =>
    key.isNotEmpty && key.length <= 255 && key.codeUnits.every((c) => c < 128);

/// Opens a box of strings. When Hive cannot read the file (a key longer
/// than 255 characters written by an older build corrupts it), the file is
/// kept as `<name>.corrupt-<ms>.hive.bak`, the entries are salvaged with
/// [salvageHiveFrames] and written to a fresh box, so one bad write cannot
/// keep the app from starting.
Future<Box<String>> openStringBox(String name) async {
  try {
    return await Hive.openBox<String>(name);
  } catch (e) {
    final dir = hiveDirectory;
    if (dir == null) rethrow;
    debugPrint('Box $name is unreadable, salvaging it: $e');
    final file = File('$dir/${name.toLowerCase()}.hive');
    final entries = <String, String>{};
    if (await file.exists()) {
      final bytes = await file.readAsBytes();
      await file.copy(
        '$dir/${name.toLowerCase()}.corrupt-'
        '${DateTime.now().millisecondsSinceEpoch}.hive.bak',
      );
      entries.addAll(salvageHiveFrames(bytes));
    }
    await Hive.deleteBoxFromDisk(name);
    final box = await Hive.openBox<String>(name);
    await box.putAll({
      for (final MapEntry(:key, :value) in entries.entries)
        if (isValidHiveKey(key)) key: value,
    });
    debugPrint('Box $name: salvaged ${box.length} entries');
    return box;
  }
}

/// Reads the string entries of a Hive box file, in write order. Each frame
/// is `[length u32][key type u8][key length u8][key][value][crc u32]`, and
/// its length is right even when its key length overflowed, so frames stay
/// in step. An entry whose key cannot be read is keyed by the `slug` or
/// `id` field of its JSON value.
@visibleForTesting
Map<String, String> salvageHiveFrames(Uint8List bytes) {
  final data = ByteData.sublistView(bytes);
  final entries = <String, String>{};
  var offset = 0;
  while (offset + 8 <= bytes.length) {
    final length = data.getUint32(offset, Endian.little);
    if (length < 8 || offset + length > bytes.length) break;
    final body = Uint8List.sublistView(bytes, offset + 4, offset + length - 4);
    offset += length;
    // String keys only: every box here is keyed by strings.
    if (body.length < 2 || body[0] != 1) continue;
    final keyLength = body[1];

    // Deletion: the key and nothing else.
    if (body.length == 2 + keyLength) {
      entries.remove(_text(body.sublist(2)));
      continue;
    }

    // Intact frame: key, then a string value `[type u8][length u32][utf8]`.
    final valueAt = 2 + keyLength;
    if (valueAt + 5 <= body.length) {
      final valueLength = ByteData.sublistView(
        body,
      ).getUint32(valueAt + 1, Endian.little);
      if (valueAt + 5 + valueLength == body.length) {
        entries[_text(body.sublist(2, valueAt))] = _text(
          body.sublist(valueAt + 5),
        );
        continue;
      }
    }

    // Key length overflowed. A deletion still holds just the key; a value
    // is found as JSON and keyed by its slug.
    final brace = body.indexOf(0x7B, 2);
    if (brace < 0) {
      if ((body.length - 2) % 256 == keyLength) {
        entries.remove(_text(body.sublist(2)));
      }
      continue;
    }
    final value = _text(body.sublist(brace));
    try {
      final json = jsonDecode(value);
      final key = json is Map ? json['slug'] ?? json['id'] : null;
      if (key is String) entries[key] = value;
    } on FormatException {
      // Not JSON: lost.
    }
  }
  return entries;
}

String _text(List<int> bytes) => utf8.decode(bytes, allowMalformed: true);
