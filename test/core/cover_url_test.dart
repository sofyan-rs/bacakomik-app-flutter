import 'package:yoru/core/utils/cover_url.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('absoluteCover', () {
    test('resolves a path on the site against the base URL', () {
      expect(
        absoluteCover('/images/covers/73/54/a.jpg', 'https://comix.to'),
        'https://comix.to/images/covers/73/54/a.jpg',
      );
      expect(
        absoluteCover('/images/a.jpg', 'https://comix.to/home/'),
        'https://comix.to/images/a.jpg',
      );
    });

    test('gives a protocol-relative URL the base scheme', () {
      expect(
        absoluteCover('//cdn.example.com/a.jpg', 'https://comix.to'),
        'https://cdn.example.com/a.jpg',
      );
    });

    test('leaves full URLs, mihon:// and empty covers alone', () {
      for (final cover in [
        'https://comix.to/a.jpg',
        'mihon://123/cover/abc',
        '',
      ]) {
        expect(absoluteCover(cover, 'https://comix.to'), cover);
      }
    });

    test('leaves a path alone without a usable base URL', () {
      expect(absoluteCover('/a.jpg', ''), '/a.jpg');
      expect(absoluteCover('/a.jpg', 'comix.to'), '/a.jpg');
    });
  });

  group('presignedUrlExpired', () {
    // Signed 6 Nov 2026 20:16:59 UTC for 6 days: expires 12 Nov 20:16:59.
    const url =
        'https://cvr.voratoon.id/prod/series/x/cover/a.webp'
        '?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Date=20261106T201659Z'
        '&X-Amz-Expires=518400&X-Amz-Signature=abc';

    test('false while valid, true from 12 hours before it expires', () {
      expect(presignedUrlExpired(url, DateTime.utc(2026, 11, 11, 8)), isFalse);
      expect(presignedUrlExpired(url, DateTime.utc(2026, 11, 12, 9)), isTrue);
      expect(presignedUrlExpired(url, DateTime.utc(2026, 11, 20)), isTrue);
    });

    test('false for URLs that are not presigned', () {
      final now = DateTime.utc(2030);
      expect(presignedUrlExpired('https://a.com/c.jpg', now), isFalse);
      expect(
        presignedUrlExpired('https://a.com/c.jpg?X-Amz-Date=x', now),
        isFalse,
      );
      expect(presignedUrlExpired('', now), isFalse);
      expect(presignedUrlExpired('mihon://1/cover/abc', now), isFalse);
    });
  });
}
