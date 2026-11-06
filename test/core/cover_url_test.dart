import 'package:bacakomik_app/core/utils/cover_url.dart';
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
}
