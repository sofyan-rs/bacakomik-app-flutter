import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:bacakomik_app/core/storage/box_recovery.dart';
import 'package:bacakomik_app/core/storage/json_box.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
// ignore: implementation_imports
import 'package:hive_ce/src/crypto/crc32.dart';

/// One Hive frame: `[length][1][key length u8][key][4][value length][value][crc]`,
/// or a deletion when [value] is null.
List<int> frame(String key, String? value) {
  final keyBytes = ascii.encode(key);
  final valueBytes = value == null ? null : utf8.encode(value);
  final body = BytesBuilder()
    ..addByte(1)
    ..addByte(keyBytes.length & 0xff)
    ..add(keyBytes);
  if (valueBytes != null) {
    body
      ..addByte(4)
      ..add(_u32(valueBytes.length))
      ..add(valueBytes);
  }
  final framed = Uint8List.fromList([
    ..._u32(body.length + 8),
    ...body.toBytes(),
  ]);
  return [...framed, ..._u32(Crc32.compute(framed))];
}

List<int> _u32(int v) =>
    (ByteData(4)..setUint32(0, v, Endian.little)).buffer.asUint8List();

void main() {
  late Directory dir;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('bacakomik_recovery_');
    Hive.init(dir.path);
    hiveDirectory = dir.path;
  });

  tearDown(() async {
    await Hive.close();
    hiveDirectory = null;
    await dir.delete(recursive: true);
  });

  String entry(String slug) => jsonEncode({'slug': slug, 'title': slug});

  test('a key over 255 characters is salvaged by its slug', () async {
    // Release builds skip Hive's key length assert and write the length
    // byte modulo 256; build such a file by hand.
    final long = 'mangafire:${'x' * 250}';
    await File('${dir.path}/bookmarks.hive').writeAsBytes([
      ...frame('a', entry('a')),
      ...frame(long, entry(long)),
      ...frame('b', entry('b')),
      ...frame('gone', entry('gone')),
      ...frame('gone', null),
      ...frame('a', entry('a')),
    ]);

    // Hive itself can no longer read the file.
    await expectLater(Hive.openBox<String>('bookmarks'), throwsA(anything));
    await Hive.close();

    final recovered = await openStringBox('bookmarks');

    // The over-long key cannot be stored again, so it is dropped.
    expect(recovered.keys.toSet(), {'a', 'b'});
    expect(jsonDecode(recovered.get('b')!)['title'], 'b');
    expect(
      dir.listSync().where((f) => f.path.contains('bookmarks.corrupt-')),
      hasLength(1),
    );
  });

  test('JsonBox skips keys Hive cannot store', () async {
    final box = JsonBox<Map<String, dynamic>>(
      await Hive.openBox<String>('bookmarks'),
      fromJson: (j) => j,
      toJson: (v) => v,
      keyOf: (v) => v['slug'] as String,
    );
    await box.putAll([
      {'slug': 'ok'},
      {'slug': 'x' * 300},
      {'slug': 'café'},
    ]);
    await Hive.close();
    final reopened = await Hive.openBox<String>('bookmarks');
    expect(reopened.keys, ['ok']);
  });
}
