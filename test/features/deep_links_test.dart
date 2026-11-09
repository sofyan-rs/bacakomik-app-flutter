import 'package:yoru/core/utils/deep_links.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('comic links round-trip', () {
    final link = DeepLinks.comic('magic-emperor');

    expect(
      link.toString(),
      'https://yoru.kurodev.org/series/magic-emperor',
    );
    expect(DeepLinks.comicSlug(link), 'magic-emperor');
  });

  test('links on the old host still open', () {
    expect(
      DeepLinks.comicSlug(
        Uri.parse('https://bacakomik.kurodev.org/series/magic-emperor'),
      ),
      'magic-emperor',
    );
  });

  test('a trailing slash and query are accepted', () {
    expect(
      DeepLinks.comicSlug(
        Uri.parse('https://yoru.kurodev.org/series/magic-emperor/?ref=wa'),
      ),
      'magic-emperor',
    );
  });

  test('other links are ignored', () {
    for (final link in [
      'https://yoru.kurodev.org/',
      'https://yoru.kurodev.org/series',
      'https://yoru.kurodev.org/series/a/b',
      'https://yoru.kurodev.org/chapter/a',
      'https://example.com/series/magic-emperor',
    ]) {
      expect(DeepLinks.comicSlug(Uri.parse(link)), isNull, reason: link);
    }
  });

  test('placeholder title from the slug', () {
    expect(DeepLinks.titleFromSlug('magic-emperor'), 'Magic Emperor');
    expect(DeepLinks.titleFromSlug('one--piece'), 'One Piece');
    expect(DeepLinks.titleFromSlug('voratoon:magic-emperor'), 'Magic Emperor');
  });
}
