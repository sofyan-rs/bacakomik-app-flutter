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

    test('on Windows maps the product name folder', () {
      expect(
        oldDataFolder(
          path(['C:', 'Users', 'u', 'AppData', 'Roaming', 'kurodev', 'Yoru']),
          windows: true,
        ),
        path([
          'C:',
          'Users',
          'u',
          'AppData',
          'Roaming',
          'kurodev',
          'BacaKomik',
        ]),
      );
      expect(
        oldDataFolder(path(['C:', 'kurodev', 'Other']), windows: true),
        isNull,
      );
    });
  });

  group('moveDataFolder', () {
    late Directory root;
    setUp(() => root = Directory.systemTemp.createTempSync('yoru_move_'));
    tearDown(() => root.deleteSync(recursive: true));

    Directory dir(String name) => Directory('${root.path}$sep$name');

    test('moves the old folder into an empty new one', () {
      final old = dir('BacaKomik')..createSync();
      File('${old.path}${sep}bookmarks.hive').writeAsStringSync('x');
      final current = dir('Yoru')..createSync();

      moveDataFolder(old, current);

      expect(old.existsSync(), isFalse);
      expect(
        File('${current.path}${sep}bookmarks.hive').readAsStringSync(),
        'x',
      );
    });

    test('keeps the new folder when it already has data', () {
      final old = dir('BacaKomik')..createSync();
      File('${old.path}${sep}bookmarks.hive').writeAsStringSync('old');
      final current = dir('Yoru')..createSync();
      File('${current.path}${sep}bookmarks.hive').writeAsStringSync('new');

      moveDataFolder(old, current);

      expect(old.existsSync(), isTrue);
      expect(
        File('${current.path}${sep}bookmarks.hive').readAsStringSync(),
        'new',
      );
    });

    test('does nothing without an old folder', () {
      final current = dir('Yoru')..createSync();
      moveDataFolder(dir('BacaKomik'), current);
      expect(current.existsSync(), isTrue);
    });
  });
}
