import 'package:bacakomik_app/core/error/exceptions.dart';
import 'package:bacakomik_app/core/source/comic_key.dart';
import 'package:bacakomik_app/core/source/extension_meta.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ComicKey', () {
    test('default source keeps the bare slug', () {
      expect(ComicKey.of('bacakomik', 'solo-leveling'), 'solo-leveling');
      expect(ComicKey.sourceOf('solo-leveling'), 'bacakomik');
      expect(ComicKey.slugOf('solo-leveling'), 'solo-leveling');
    });

    test('other sources prefix the slug', () {
      const key = 'voratoon:solo-leveling';
      expect(ComicKey.of('voratoon', 'solo-leveling'), key);
      expect(ComicKey.sourceOf(key), 'voratoon');
      expect(ComicKey.slugOf(key), 'solo-leveling');
    });
  });

  group('FilterGroup.tryParse', () {
    test('parses a select group', () {
      final group = FilterGroup.tryParse({
        'key': 'status',
        'label': 'Status',
        'type': 'select',
        'default': 'ongoing',
        'options': [
          {'value': '', 'label': 'All'},
          {'value': 'ongoing', 'label': 'Ongoing'},
        ],
      })!;

      expect(group.key, 'status');
      expect(group.label, 'Status');
      expect(group.multi, isFalse);
      expect(group.quick, isFalse);
      expect(group.options.map((o) => o.value), ['', 'ongoing']);
      expect(group.defaults, ['ongoing']);
      expect(group.labelOf('ongoing'), 'Ongoing');
      expect(group.labelOf('unknown'), 'unknown');
    });

    test('select group without default uses its first option', () {
      final group = FilterGroup.tryParse({
        'key': 'sort',
        'options': [
          {'value': 'latest', 'label': 'Latest'},
        ],
      })!;

      expect(group.label, 'sort');
      expect(group.defaults, ['latest']);
    });

    test('parses a quick multi group, stringifying option values', () {
      final group = FilterGroup.tryParse({
        'key': FilterGroup.genreKey,
        'type': 'multi',
        'quick': true,
        'options': [
          {'value': 1, 'label': 'Action'},
        ],
      })!;

      expect(group.multi, isTrue);
      expect(group.quick, isTrue);
      expect(group.options.single.value, '1');
      expect(group.defaults, isEmpty);
    });

    test('rejects unusable groups', () {
      expect(FilterGroup.tryParse('status'), isNull);
      expect(FilterGroup.tryParse({'label': 'No key', 'type': 'multi'}), isNull);
      expect(
        FilterGroup.tryParse({'key': 'status', 'options': <Object>[]}),
        isNull,
      );
    });
  });

  group('SourceFeatures', () {
    final features = SourceFeatures.fromJson(
      home: {
        'featured': {'sort': 'newseries'},
        'latest': {
          'sort': ['latest'],
          'genre': [1, 2],
        },
      },
      groups: [
        {
          'key': 'sort',
          'options': [
            {'value': 'latest', 'label': 'Latest'},
            {'value': 'az', 'label': 'A-Z'},
          ],
        },
        'garbage',
        {
          'key': 'genre',
          'type': 'multi',
          'quick': true,
          'options': [
            {'value': '1', 'label': 'Action'},
          ],
        },
      ],
    );

    test('fromJson keeps usable groups and normalizes home filters', () {
      expect(features.groups.map((g) => g.key), ['sort', 'genre']);
      expect(features.featured, {
        'sort': ['newseries'],
      });
      expect(features.latest, {
        'sort': ['latest'],
        'genre': ['1', '2'],
      });
    });

    test('fromJson tolerates missing home and groups', () {
      final empty = SourceFeatures.fromJson();

      expect(empty.groups, isEmpty);
      expect(empty.featured, isEmpty);
      expect(empty.latest, isEmpty);
      expect(empty.quick, isNull);
    });

    test('group and quick', () {
      expect(features.group('genre')?.multi, isTrue);
      expect(features.group('missing'), isNull);
      expect(features.quick?.key, 'genre');
    });

    test('valueOf prefers picked values, then group defaults', () {
      expect(
        features.valueOf({
          'sort': ['az'],
        }, 'sort'),
        ['az'],
      );
      expect(features.valueOf({}, 'sort'), ['latest']);
      expect(features.valueOf({}, 'genre'), isEmpty);
      expect(features.valueOf({}, 'missing'), isEmpty);
    });
  });

  group('ExtensionMeta.version', () {
    ExtensionMeta meta(Object version) => ExtensionMeta.fromJson({
      'id': 'x',
      'name': 'X',
      'version': version,
      'file': 'x.js',
      'sha256': '',
    });

    test('reads integers stored by older builds as major versions', () {
      expect(meta(2).version, '2.0.0');
    });

    test('compares as semver, not as text', () {
      expect(meta('1.10.0').isNewerThan(meta('1.9.0')), isTrue);
      expect(meta('1.0.0').isNewerThan(meta(1)), isFalse);
      expect(meta('1.0.1').isNewerThan(meta(1)), isTrue);
    });
  });

  group('Challenge', () {
    test('reads the URL back from an error message', () {
      final message = Challenge.message('https://mangafire.to/');
      expect(Challenge.urlOf(message), 'https://mangafire.to/');
      expect(Challenge.urlOf('Error: $message'), 'https://mangafire.to/');
    });

    test('ignores other errors', () {
      expect(Challenge.urlOf('404 Not found'), isNull);
      expect(Challenge.urlOf('challenge: not-a-url'), isNull);
    });
  });

  group('ExtensionMeta languages', () {
    final dex = ExtensionMeta.fromJson({
      'id': 'mangadex',
      'name': 'MangaDex',
      'lang': 'all',
      'version': '1.0.0',
      'file': 'x.js',
      'sha256': '',
      'languages': ['en', 'id', 'pt-br'],
    });

    test('each language is a source with its own id', () {
      final id = dex.forLanguage('id');
      expect(id.id, 'mangadex-id');
      expect(id.name, 'MangaDex (ID)');
      expect(id.baseName, 'MangaDex');
      expect(id.lang, 'id');
      expect(id.extensionId, 'mangadex');
    });

    test('sourceFor matches the extension and its languages only', () {
      expect(dex.sourceFor('mangadex')?.id, 'mangadex');
      expect(dex.sourceFor('mangadex-pt-br')?.lang, 'pt-br');
      expect(dex.sourceFor('mangadex-fr'), isNull);
      expect(dex.sourceFor('mangafire'), isNull);
    });

    test('languages survive a round trip', () {
      expect(ExtensionMeta.fromJson(dex.toJson()).languages, dex.languages);
    });
  });
}
