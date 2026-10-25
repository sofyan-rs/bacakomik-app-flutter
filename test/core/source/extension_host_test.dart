import 'dart:convert';

import 'package:bacakomik_app/core/source/extension_bridge.dart';
import 'package:bacakomik_app/core/source/extension_runtime.dart';
import 'package:bacakomik_app/core/storage/box_recovery.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ExtensionBridge.storageKey', () {
    test('keeps keys Hive can store as they were', () {
      expect(
        ExtensionBridge.storageKey('mangafire', 'token'),
        'mangafire:token',
      );
      final long = 'k' * (255 - 'mangafire:'.length);
      expect(ExtensionBridge.storageKey('mangafire', long), 'mangafire:$long');
    });

    test('hashes keys that are too long or not ASCII', () {
      for (final key in ['k' * 300, 'judul-漫画', 'é']) {
        final stored = ExtensionBridge.storageKey('mangafire', key);
        expect(isValidHiveKey(stored), isTrue, reason: key);
        expect(stored, startsWith('mangafire:#'));
        expect(stored, ExtensionBridge.storageKey('mangafire', key));
      }
      expect(
        ExtensionBridge.storageKey('mangafire', 'k' * 300),
        isNot(ExtensionBridge.storageKey('mangafire', 'k' * 301)),
      );
      expect(
        ExtensionBridge.storageKey('a', 'é'),
        isNot(ExtensionBridge.storageKey('b', 'é')),
      );
    });
  });

  group('ExtensionBridge.select', () {
    const item = '<li class="c"><a href="/x">Chapter <b>1</b></a></li>';

    test('reads matching elements', () async {
      final found = await ExtensionBridge.select('<ul>$item</ul>', 'li.c a');
      expect(found, [
        {
          'text': 'Chapter 1',
          'html': 'Chapter <b>1</b>',
          'outerHtml': '<a href="/x">Chapter <b>1</b></a>',
          'attrs': {'href': '/x'},
        },
      ]);
    });

    test('parses a large page on another isolate the same way', () async {
      final page = '<ul>${item * 2000}</ul>';
      expect(page.length, greaterThan(ExtensionBridge.offThreadSelectLength));
      final found = await ExtensionBridge.select(page, 'li.c a');
      expect(found, hasLength(2000));
      expect(found.first['attrs'], {'href': '/x'});
    });
  });

  group('ExtensionRuntime.jsLiteral', () {
    test('is the JSON itself, encoded once', () {
      final value = {
        'status': 200,
        'body': '<p class="a">"quoted" \\ back</p>\n',
        'headers': {'content-type': 'text/html'},
        'list': [1, null, true, 'x'],
      };
      final literal = ExtensionRuntime.jsLiteral(value);
      expect(literal, jsonEncode(value));
      expect(jsonDecode(literal), value);
      expect(ExtensionRuntime.jsLiteral(null), 'null');
      expect(ExtensionRuntime.jsLiteral('text'), '"text"');
    });

    test('escapes line and paragraph separators', () {
      final literal = ExtensionRuntime.jsLiteral(['a b c']);
      expect(literal, r'["a b c"]');
      expect(jsonDecode(literal), ['a b c']);
    });

    test('parses values with a __proto__ key instead of inlining them', () {
      final value = {
        '__proto__': {'polluted': true},
      };
      final literal = ExtensionRuntime.jsLiteral(value);
      expect(literal, startsWith('JSON.parse('));
      final inner = literal.substring('JSON.parse('.length, literal.length - 1);
      expect(jsonDecode(jsonDecode(inner) as String), value);
    });
  });
}
