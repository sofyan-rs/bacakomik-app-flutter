import 'dart:typed_data';

import 'package:bacakomik_app/core/utils/utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Uint8List bytes(List<int> b) => Uint8List.fromList([...b, 0, 0, 0, 0]);

  test('imageExtension reads the format from the first bytes', () {
    expect(imageExtension(bytes([0xFF, 0xD8, 0xFF, 0xE0])), '.jpg');
    expect(imageExtension(bytes([0x89, 0x50, 0x4E, 0x47])), '.png');
    expect(imageExtension(bytes('GIF89a'.codeUnits)), '.gif');
    expect(
      imageExtension(
        bytes([...'RIFF'.codeUnits, 1, 2, 3, 4, ...'WEBP'.codeUnits]),
      ),
      '.webp',
    );
  });

  test('imageExtension is null for other formats', () {
    // AVIF: ....ftypavif
    expect(
      imageExtension(bytes([0, 0, 0, 0x1C, ...'ftypavif'.codeUnits])),
      isNull,
    );
    expect(imageExtension(bytes('RIFF....WAVE'.codeUnits)), isNull);
    expect(imageExtension(Uint8List(0)), isNull);
  });
}
