import 'package:bacakomik_app/core/utils/deep_links.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('comic links round-trip', () {
    final link = DeepLinks.comic('magic-emperor');

    expect(
      link.toString(),
      'https://bacakomik.kurodev.org/series/magic-emperor',
    );
    expect(DeepLinks.comicSlug(link), 'magic-emperor');
  });

  test('a trailing slash and query are accepted', () {
    expect(
      DeepLinks.comicSlug(
        Uri.parse('https://bacakomik.kurodev.org/series/magic-emperor/?ref=wa'),
      ),
      'magic-emperor',
    );
  });

  test('other links are ignored', () {
    for (final link in [
      'https://bacakomik.kurodev.org/',
      'https://bacakomik.kurodev.org/series',
      'https://bacakomik.kurodev.org/series/a/b',
      'https://bacakomik.kurodev.org/chapter/a',
      'https://example.com/series/magic-emperor',
    ]) {
      expect(DeepLinks.comicSlug(Uri.parse(link)), isNull, reason: link);
    }
  });

  test('placeholder title from the slug', () {
    expect(DeepLinks.titleFromSlug('magic-emperor'), 'Magic Emperor');
    expect(DeepLinks.titleFromSlug('one--piece'), 'One Piece');
  });
}
