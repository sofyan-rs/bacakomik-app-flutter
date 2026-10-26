import 'dart:convert';
import 'dart:io';

import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:bacakomik_app/core/data/models/comic_details_model.dart';
import 'package:bacakomik_app/core/data/models/series_response.dart';
import 'package:bacakomik_app/core/error/exceptions.dart';
import 'package:bacakomik_app/core/source/comic_key.dart';
import 'package:bacakomik_app/core/source/extension_meta.dart';
import 'package:bacakomik_app/core/source/mihon_host.dart';
import 'package:bacakomik_app/core/source/mihon_repo.dart';
import 'package:bacakomik_app/core/source/mihon_source.dart';
import 'package:bacakomik_app/core/source/mihon_store.dart';
import 'package:bacakomik_app/features/migration/domain/entities/mihon_backup.dart';
import 'package:bacakomik_app/features/migration/domain/entities/mihon_import_plan.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeMihonHost implements MihonHost {
  final calls = <(String, Map<String, Object?>)>[];
  Object? result;

  @override
  Future<bool> get available async => true;

  @override
  Future<Object?> handle(String method, Map<String, Object?> args) async {
    calls.add((method, args));
    return result;
  }

  @override
  Future<({Uint8List bytes, String? type})> image(String url) =>
      throw UnimplementedError();

  @override
  Future<String?> httpUrl(String url) async => null;
}

const _dexEntry = {
  'name': 'Tachiyomi: MangaDex',
  'pkg': 'eu.kanade.tachiyomi.extension.all.mangadex',
  'apk': 'tachiyomi-all.mangadex-v1.4.200.apk',
  'lang': 'all',
  'code': 200,
  'version': '1.4.200',
  'nsfw': 1,
  'sources': [
    {
      'name': 'MangaDex',
      'lang': 'en',
      'id': '2499283573021220255',
      'baseUrl': 'https://mangadex.org',
    },
    {
      'name': 'MangaDex',
      'lang': 'id',
      'id': '1411768577036936240',
      'baseUrl': 'https://mangadex.org',
    },
  ],
};

ExtensionMeta _dex({int code = 200, String version = '1.4.200'}) =>
    MihonRepo.entry(
      {..._dexEntry, 'code': code, 'version': version},
      repoUrl: 'https://repo.test/index.min.json',
      signer: 'ABCD',
    )!;

void main() {
  group('MihonRepo', () {
    test('normalizes what users paste to the index URL', () {
      expect(
        MihonRepo.normalize('https://repo.test/index.min.json'),
        'https://repo.test/index.min.json',
      );
      expect(
        MihonRepo.normalize('https://repo.test/a/repo.json'),
        'https://repo.test/a/index.min.json',
      );
      expect(
        MihonRepo.normalize('https://repo.test/a'),
        'https://repo.test/a/index.min.json',
      );
      expect(MihonRepo.normalize('https://repo.test/other.json'), isNull);
      expect(MihonRepo.normalize('repo.test'), isNull);
      expect(MihonRepo.isRepoUrl('https://repo.test/index.min.json'), isTrue);
      expect(MihonRepo.isRepoUrl('https://repo.test/index.json'), isFalse);
    });

    test('reads an index entry', () {
      final meta = _dex();
      expect(meta.id, 'mihon-all_mangadex');
      expect(meta.name, 'MangaDex');
      expect(meta.isMihon, isTrue);
      expect(meta.nsfw, isTrue);
      expect(meta.signer, 'abcd');
      expect(meta.versionCode, 200);
      expect(meta.languages, ['en', 'id']);
      expect(meta.supported, isTrue);
      expect(
        meta.iconUrl,
        'https://repo.test/icon/eu.kanade.tachiyomi.extension.all.mangadex.png',
      );
      expect(
        Uri.parse(meta.repoUrl!).resolve(meta.file).toString(),
        'https://repo.test/apk/tachiyomi-all.mangadex-v1.4.200.apk',
      );
    });

    test('an unknown lib is listed but not supported', () {
      expect(_dex(version: '1.9.1').supported, isFalse);
    });
  });

  group('ExtensionMeta for Mihon', () {
    test('survives storage', () {
      final meta = _dex();
      final back = ExtensionMeta.fromJson(
        jsonDecode(jsonEncode(meta.toJson())) as Map<String, dynamic>,
      );
      expect(back.pkg, meta.pkg);
      expect(back.signer, meta.signer);
      expect(back.versionCode, 200);
      expect(back.icon, meta.icon);
      expect(back.mihonSources.map((s) => (s.id, s.lang)), [
        ('2499283573021220255', 'en'),
        ('1411768577036936240', 'id'),
      ]);
    });

    test('each source is mihon-<id>, without a colon', () {
      final meta = _dex();
      final sources = meta.mihonSourcesIn(['id']);
      expect(sources.map((s) => (s.id, s.name, s.extensionId)), [
        ('mihon-1411768577036936240', 'MangaDex (ID)', 'mihon-all_mangadex'),
      ]);
      expect(sources.single.isMihon, isTrue);
      expect(meta.sourceFor('mihon-2499283573021220255')?.lang, 'en');
      expect(meta.sourceFor('mihon-all_mangadex-en'), isNull);
      final key = ComicKey.of(sources.single.id, 'abc');
      expect(ComicKey.sourceOf(key), 'mihon-1411768577036936240');
    });

    test('updates compare version codes', () {
      expect(_dex(code: 201).isNewerThan(_dex()), isTrue);
      expect(_dex().isNewerThan(_dex(code: 201)), isFalse);
    });

    test('slugs are the URL as unpadded base64url', () {
      final slug = ExtensionMeta.mihonSlug('/title/ä?x=1');
      expect(slug, isNot(contains('=')));
      expect(slug, isNot(contains('/')));
      expect(ComicKey.storable('mihon-1:$slug'), isTrue);
      expect(
        utf8.decode(base64Url.decode(base64Url.normalize(slug))),
        '/title/ä?x=1',
      );
    });
  });

  group('MihonSource', () {
    test('calls the host with the Mihon source id', () async {
      final host = FakeMihonHost()..result = {'items': [], 'hasNext': false};
      final source = MihonSource(_dex().mihonSourcesIn(['en']).single, host);
      await source.call('browse', [
        {'page': 1},
      ]);
      expect(host.calls.single.$1, 'call');
      expect(host.calls.single.$2, {
        'source': '2499283573021220255',
        'method': 'browse',
        'args': [
          {'page': 1},
        ],
      });
    });

    test('reads filters and Home from features', () async {
      final host = FakeMihonHost()
        ..result = {
          'filters': [
            {
              'key': 'f0',
              'label': 'Sort',
              'type': 'select',
              'options': [
                {'value': '0', 'label': 'Popular'},
              ],
              'default': '0',
            },
          ],
          'home': {
            'featured': {
              '_list': ['popular'],
            },
            'latest': {
              '_list': ['latest'],
            },
          },
        };
      final source = MihonSource(_dex().mihonSourcesIn(['en']).single, host);
      final features = await source.features();
      expect(features.groups.single.key, 'f0');
      expect(features.latest, {
        '_list': ['latest'],
      });
    });
  });

  group('ChannelMihonHost.failure', () {
    test('a browser check becomes a challenge', () {
      final e = ChannelMihonHost.failure(
        PlatformException(
          code: '403',
          message: 'check',
          details: {'verifyUrl': 'https://site.test/'},
        ),
      );
      expect(Challenge.urlOf(e.message), 'https://site.test/');
    });

    test('a missing series is a 404', () {
      final e = ChannelMihonHost.failure(
        PlatformException(code: '404', message: 'Gone'),
      );
      expect(e.statusCode, 404);
      expect(e.message, startsWith('404'));
    });
  });

  group('MihonStore', () {
    final source = [
      ..._field(1, 3639673976007021338),
      ..._field(2, 'Kiryuu'),
      ..._field(3, 'id'),
      ..._field(4, 'https://kiryuu.test'),
    ];
    final extension = [
      ..._field(1, 'Kiryuu'),
      ..._field(2, 'eu.kanade.tachiyomi.extension.id.kiryuu'),
      ..._field(3, [
        ..._field(1, 'https://cdn.test/kiryuu.apk'),
        ..._field(2, 'https://cdn.test/kiryuu.png'),
      ]),
      ..._field(4, '1.6'),
      ..._field(5, 106060),
      ..._field(6, '1.6.60'),
      ..._field(7, 3),
      ..._field(8, source),
    ];
    final store = gzip.encode([
      ..._field(1, 'Keiyoushi'),
      ..._field(3, 'ABC123'),
      ..._field(101, _field(1, extension)),
    ]);

    test('reads a gzipped store with its extensions', () {
      final parsed = MihonStore.parse(store);
      expect(parsed.signingKey, 'ABC123');
      final e = parsed.extensions!.single;
      expect(
        (e.name, e.pkg, e.lib, e.versionCode, e.nsfw),
        (
          'Kiryuu',
          'eu.kanade.tachiyomi.extension.id.kiryuu',
          '1.6',
          106060,
          true,
        ),
      );
      expect(e.sources.single.id, '3639673976007021338');

      final meta = MihonRepo.fromStore(
        e,
        repoUrl: 'https://repo.test/index.min.json',
        signer: 'ABC123',
      )!;
      expect(meta.id, 'mihon-id_kiryuu');
      expect(meta.lang, 'id');
      expect(meta.signer, 'abc123');
      expect(meta.supported, isTrue);
      expect(
        Uri.parse(meta.repoUrl!).resolve(meta.file).toString(),
        'https://cdn.test/kiryuu.apk',
      );
      expect(meta.iconUrl, 'https://cdn.test/kiryuu.png');
    });

    test('reads a bare extension list', () {
      final list = MihonStore.parseList(_field(1, extension));
      expect(list.single.versionName, '1.6.60');
      expect(MihonStore.parse(_field(1, extension)).extensions, hasLength(1));
    });
  });

  test('Home sections follow what a Mihon source offers', () {
    final popularOnly = SourceFeatures.fromJson(
      home: {
        'featured': null,
        'latest': {
          '_list': ['popular'],
        },
        'latestLabel': 'Popular',
      },
    );
    expect(popularOnly.showFeatured, isFalse);
    expect(popularOnly.latestLabel, 'Popular');
    final js = SourceFeatures.fromJson(home: {'featured': {}, 'latest': {}});
    expect(
      (js.showFeatured, js.featuredLabel, js.latestLabel),
      (true, null, null),
    );
  });

  test('a genre finds its filter by id, else by label', () {
    final features = SourceFeatures.fromJson(
      groups: [
        {
          'key': 'f2',
          'label': 'Genres',
          'type': 'multi',
          'options': [
            {'value': '0', 'label': 'Action'},
            {'value': '1', 'label': 'Slice of Life'},
          ],
        },
      ],
    );
    expect(features.genreFilter('slice-of-life', 'Slice of life'), (
      key: 'f2',
      value: '1',
    ));
    expect(features.genreFilter('romance', 'Romance'), isNull);
    final js = SourceFeatures.fromJson(
      groups: [
        {
          'key': 'genre',
          'type': 'multi',
          'options': [
            {'value': '7', 'label': 'Isekai'},
          ],
        },
      ],
    );
    expect(js.genreFilter('7', 'Something else'), (key: 'genre', value: '7'));
  });

  test('a made-up chapter number keeps the name of the chapter', () {
    final chapter = ChapterResponse.fromJson({
      'number': 9.001,
      'title': 'Extra',
    }).toEntity('mihon-1:abc');
    expect(
      (chapter.number, chapter.slug, chapter.title),
      ('9.001', 'mihon-1:abc/9.001', 'Extra'),
    );
    expect(AppText.chapterName(chapter.number, chapter.title), 'Extra');
    expect(AppText.chapterName('9'), 'Chapter 9');
    // Stored chapters without a name stay as they were.
    expect(const ChapterModel(number: '9', slug: 's/9', date: '-').toJson(), {
      'number': '9',
      'slug': 's/9',
      'date': '-',
    });
    expect(
      ChapterModel.fromJson({'number': '9', 'slug': 's/9', 'date': '-'}).title,
      isNull,
    );
  });

  test('a Mihon backup prefers what is installed, JS first', () {
    final mihon = MihonRepo.entry(
      {
        'name': 'Tachiyomi: Asura Scans',
        'pkg': 'eu.kanade.tachiyomi.extension.en.asurascans',
        'apk': 'asura.apk',
        'code': 1,
        'version': '1.6.1',
        'sources': [
          {'name': 'Asura Scans', 'lang': 'en', 'id': '777'},
        ],
      },
      repoUrl: 'https://repo.test/index.min.json',
      signer: 'k',
    )!;
    const js = ExtensionMeta(
      id: 'asura',
      name: 'Asura Scans',
      lang: 'en',
      version: '1.0.0',
      apiVersion: 1,
      baseUrl: 'https://asura.test',
      file: 'asura.js',
      sha256: '',
      urlPatterns: [r'^/series/([^/]+)'],
    );
    final backup = MihonBackup(
      sourceNames: {777: 'Asura Scans'},
      categories: const {},
      manga: const [
        MihonManga(sourceId: 777, url: '/series/abc', title: 'Abc'),
      ],
    );
    String? pick(Set<String> installed) => planMihonImport(backup, [
      js,
      mihon,
    ], installed: installed).single.source?.id;
    // Only the repos: the JS source.
    expect(pick({}), 'asura');
    // The Mihon one is installed, the JS one only offered.
    expect(pick({mihon.id}), 'mihon-777');
    // Both installed: the JS one.
    expect(pick({'asura', mihon.id}), 'asura');
  });

  test('comics the JS source cannot read go to the Mihon one', () {
    final mihon = MihonRepo.entry(
      {
        'name': 'Tachiyomi: Site',
        'pkg': 'eu.kanade.tachiyomi.extension.en.site',
        'apk': 'site.apk',
        'code': 1,
        'version': '1.6.1',
        'sources': [
          {'name': 'Site', 'lang': 'en', 'id': '888'},
        ],
      },
      repoUrl: 'https://repo.test/index.min.json',
      signer: 'k',
    )!;
    const js = ExtensionMeta(
      id: 'site',
      name: 'Site',
      lang: 'en',
      version: '1.0.0',
      apiVersion: 1,
      baseUrl: 'https://site.test',
      file: 'site.js',
      sha256: '',
      urlPatterns: [r'^/series/([^/]+)'],
    );
    final backup = MihonBackup(
      sourceNames: {888: 'Site'},
      categories: const {},
      manga: const [
        MihonManga(sourceId: 888, url: '/series/abc', title: 'Abc'),
        MihonManga(sourceId: 888, url: '/odd/x', title: 'Odd'),
      ],
    );
    final groups = planMihonImport(backup, [js, mihon], installed: {'site'});
    expect(groups.map((g) => (g.name, g.source?.id, g.entries.length)), [
      ('Site', 'site', 1),
      ('Site (Mihon)', 'mihon-888', 1),
    ]);
  });

  test('a long Mihon URL gets a short hashed slug', () {
    final url = '/manga/${'x' * 300}';
    final slug = ExtensionMeta.mihonSlug(url);
    expect(ExtensionMeta.isHashedMihonSlug(slug), isTrue);
    expect(slug, hasLength(41));
    expect(ComicKey.storable('mihon-1234567890123456789:$slug'), isTrue);
    expect(
      ExtensionMeta.isHashedMihonSlug(ExtensionMeta.mihonSlug('/a')),
      isFalse,
    );
  });

  test('a Mihon backup matches an installed Mihon source by id', () {
    final backup = MihonBackup(
      sourceNames: {2499283573021220255: 'MangaDex'},
      categories: const {},
      manga: const [
        MihonManga(
          sourceId: 2499283573021220255,
          url: '/manga/abc',
          title: 'Abc',
        ),
      ],
    );
    final group = planMihonImport(backup, [_dex()]).single;
    expect(group.source?.id, 'mihon-2499283573021220255');
    expect(
      group.entries.single.key,
      'mihon-2499283573021220255:${ExtensionMeta.mihonSlug('/manga/abc')}',
    );
  });
}

/// Protobuf bytes for [MihonStore] tests: a varint or bytes field.
List<int> _field(int number, Object value) {
  List<int> varint(int v) {
    final out = <int>[];
    while (v >= 0x80) {
      out.add((v & 0x7f) | 0x80);
      v >>= 7;
    }
    return out..add(v);
  }

  if (value is int) return [...varint(number << 3), ...varint(value)];
  final bytes = value is String ? utf8.encode(value) : value as List<int>;
  return [...varint(number << 3 | 2), ...varint(bytes.length), ...bytes];
}
