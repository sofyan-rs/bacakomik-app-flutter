import 'dart:convert';
import 'dart:typed_data';

import 'package:bacakomik_app/core/network/image_host_support.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ImageHostCookies', () {
    late DateTime now;
    late List<Uri> reads;
    late ImageHostCookies cookies;

    setUp(() {
      now = DateTime(2026, 10, 25);
      reads = [];
      cookies = ImageHostCookies((url) async {
        reads.add(url);
        return 'cf_clearance=${reads.length}';
      }, now: () => now);
    });

    final page = Uri.parse('https://img.example.com/a/1.jpg');

    test('hosts that never turned a request away get no cookies', () async {
      expect(await cookies.header(page), '');
      expect(cookies.needs(page.host), isFalse);
      expect(reads, isEmpty);
    });

    test('a host marked once reads the cookies, then uses the cache', () async {
      expect(cookies.markNeeded(page.host), isTrue);
      expect(cookies.markNeeded(page.host), isFalse);
      expect(await cookies.header(page), 'cf_clearance=1');
      now = now.add(const Duration(minutes: 9));
      expect(
        await cookies.header(Uri.parse('https://img.example.com/b/2.jpg')),
        'cf_clearance=1',
      );
      expect(reads, hasLength(1));
    });

    test('requests at the same time share one read', () async {
      cookies.markNeeded(page.host);
      final headers = await Future.wait([
        cookies.header(page),
        cookies.header(page),
        cookies.header(page),
      ]);
      expect(headers, everyElement('cf_clearance=1'));
      expect(reads, hasLength(1));
    });

    test('reads again after the ttl or an invalidate', () async {
      cookies.markNeeded(page.host);
      await cookies.header(page);
      now = now.add(ImageHostCookies.ttl);
      expect(await cookies.header(page), 'cf_clearance=2');
      cookies.invalidate(page.host);
      expect(await cookies.header(page), 'cf_clearance=3');
    });

    test('a failed read is an empty header', () async {
      final failing = ImageHostCookies((_) async => throw StateError('none'));
      failing.markNeeded(page.host);
      expect(await failing.header(page), '');
    });
  });

  group('decodeImageBody', () {
    Uint8List bytes(int length) =>
        Uint8List.fromList([for (var i = 0; i < length; i++) i * 7 % 256]);

    test('decodes a small body', () async {
      final data = bytes(1000);
      expect(await decodeImageBody(base64Encode(data)), data);
    });

    test('decodes a large body on another isolate', () async {
      final data = bytes(300 * 1024);
      final body = base64Encode(data);
      expect(body.length, greaterThan(offThreadDecodeLength));
      expect(await decodeImageBody(body), data);
    });

    test('a broken body fails', () {
      expect(
        decodeImageBody('not base64!' * 10000),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
