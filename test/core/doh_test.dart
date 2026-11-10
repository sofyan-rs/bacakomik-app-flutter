import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:yoru/core/network/doh.dart';
import 'package:yoru/features/settings/data/models/settings_model.dart';
import 'package:yoru/features/settings/domain/entities/app_settings.dart';

/// A wire-format answer to [query] with [records] of `(type, bytes, ttl)`;
/// names are compression pointers to the question, as servers send them.
Uint8List answer(
  Uint8List query,
  List<(int, List<int>, int)> records, {
  int rcode = 0,
}) {
  final b = BytesBuilder()
    ..add([0, 0, 0x81, 0x80 | rcode, 0, 1, 0, records.length, 0, 0, 0, 0])
    ..add(query.sublist(12));
  for (final (type, data, ttl) in records) {
    b
      ..add([0xc0, 12, type >> 8, type & 0xff, 0, 1])
      ..add([ttl >> 24, (ttl >> 16) & 0xff, (ttl >> 8) & 0xff, ttl & 0xff])
      ..add([data.length >> 8, data.length & 0xff])
      ..add(data);
  }
  return b.takeBytes();
}

void main() {
  group('encodeDnsQuery', () {
    test('writes the name as labels after a recursive header', () {
      final q = encodeDnsQuery('api.mangadex.org', dnsTypeA);
      expect(q.sublist(0, 12), [0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0]);
      expect(q.sublist(12), [
        3, ...'api'.codeUnits, 8, ...'mangadex'.codeUnits, 3,
        ...'org'.codeUnits, 0, 0, 1, 0, 1, //
      ]);
    });
  });

  group('parseDnsAnswer', () {
    test('reads A records and their lowest TTL', () {
      final q = encodeDnsQuery('a.test', dnsTypeA);
      final a = parseDnsAnswer(
        answer(q, [
          (5, [0xc0, 12], 300), // a CNAME, skipped
          (dnsTypeA, [104, 18, 1, 2], 120),
          (dnsTypeA, [104, 18, 1, 3], 60),
        ]),
        dnsTypeA,
      );
      expect(a.addresses.map((a) => a.address), ['104.18.1.2', '104.18.1.3']);
      expect(a.ttl, 60);
    });

    test('reads AAAA records', () {
      final q = encodeDnsQuery('a.test', dnsTypeAaaa);
      final a = parseDnsAnswer(
        answer(q, [
          (dnsTypeAaaa, [0x26, 0x06, 0x47, 0, ...List.filled(11, 0), 1], 60),
        ]),
        dnsTypeAaaa,
      );
      expect(a.addresses.single.type, InternetAddressType.IPv6);
    });

    test('a name that does not exist has no addresses', () {
      final q = encodeDnsQuery('a.test', dnsTypeA);
      expect(parseDnsAnswer(answer(q, [], rcode: 3), dnsTypeA).addresses, []);
    });

    test('a server failure throws', () {
      final q = encodeDnsQuery('a.test', dnsTypeA);
      expect(
        () => parseDnsAnswer(answer(q, [], rcode: 2), dnsTypeA),
        throwsA(isA<SocketException>()),
      );
    });
  });

  group('DohResolver', () {
    test('lists IPv4 before IPv6 and caches the answer', () async {
      var sent = 0;
      final resolver = DohResolver(
        dohPresets.first,
        send: (query) async {
          sent++;
          final type = query[query.length - 3];
          return type == dnsTypeA
              ? answer(query, [
                  (dnsTypeA, [1, 2, 3, 4], 300),
                ])
              : answer(query, [(dnsTypeAaaa, List.filled(16, 1), 300)]);
        },
      );
      final first = await resolver.lookup('Site.Test');
      expect(first.first.address, '1.2.3.4');
      expect(first.last.type, InternetAddressType.IPv6);
      await resolver.lookup('site.test');
      expect(sent, 2);
    });

    test('a name without addresses throws', () async {
      final resolver = DohResolver(
        dohPresets.first,
        send: (query) async => answer(query, [], rcode: 3),
      );
      expect(resolver.lookup('none.test'), throwsA(isA<SocketException>()));
    });
  });

  group('DohServer.fromSetting', () {
    test('off, presets and custom URLs', () {
      expect(DohServer.fromSetting(''), isNull);
      expect(
        DohServer.fromSetting('cloudflare')?.url,
        'https://cloudflare-dns.com/dns-query',
      );
      final custom = DohServer.fromSetting('https://dns.example/dns-query');
      expect(custom?.name, 'dns.example');
      expect(custom?.bootstrap, isEmpty);
      expect(DohServer.fromSetting('http://dns.example/q'), isNull);
      expect(DohServer.fromSetting('nonsense'), isNull);
    });

    test('every preset has an https URL and bootstrap addresses', () {
      for (final p in dohPresets) {
        expect(DohServer.isValidCustomUrl(p.url), isTrue, reason: p.id);
        expect(
          p.bootstrap.map(InternetAddress.tryParse),
          everyElement(isNotNull),
        );
      }
    });
  });

  test('the setting is stored and read back', () {
    const settings = AppSettings(dnsOverHttps: 'adguard');
    final json = SettingsModel.fromEntity(settings).toJson();
    expect(SettingsModel.fromJson(json).toEntity().dnsOverHttps, 'adguard');
    expect(SettingsModel.fromJson({}).toEntity().dnsOverHttps, '');
  });
}
