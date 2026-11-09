import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yoru/core/storage/old_app_id_migration.dart';

void main() {
  final sep = Platform.pathSeparator;
  String path(List<String> parts) => parts.join(sep);

  group('oldDataFolder', () {
    test('maps the new id folder to the old one', () {
      expect(
        oldDataFolder(path(['', 'home', 'u', '.local', 'share', appId])),
        path(['', 'home', 'u', '.local', 'share', oldAppId]),
      );
    });

    test('keeps the debug suffix', () {
      expect(
        oldDataFolder(path(['', 'Support', '$appId.debug'])),
        path(['', 'Support', '$oldAppId.debug']),
      );
    });

    test('ignores a trailing separator', () {
      expect(
        oldDataFolder('${path(['', 'Support', appId])}$sep'),
        path(['', 'Support', oldAppId]),
      );
    });

    test('is null for a folder not named after the new id', () {
      expect(oldDataFolder(path(['', 'Support', 'other'])), isNull);
      expect(oldDataFolder(path(['', 'Support', '${appId}x'])), isNull);
    });
  });
}
