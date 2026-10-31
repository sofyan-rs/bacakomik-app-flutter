import 'package:bacakomik_app/features/reader/presentation/pages/read_chapter_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('pageOnScreen', () {
    test('keeps the page while the last page is off screen', () {
      expect(pageOnScreen(page: 10, pageCount: 144), 10);
      expect(pageOnScreen(page: 10, pageCount: 144, lastPageBottom: 1.4), 10);
    });

    test('reaches the last page once it is all on screen', () {
      // Short credit pages fit below the top third: page 143 of 144 stayed
      // the current one and the chapter never finished.
      expect(pageOnScreen(page: 142, pageCount: 144, lastPageBottom: 0.8), 143);
      expect(pageOnScreen(page: 142, pageCount: 144, lastPageBottom: 1), 143);
    });

    test('leaves the last page and the end of the chapter as they are', () {
      expect(pageOnScreen(page: 143, pageCount: 144, lastPageBottom: 0.5), 143);
      expect(pageOnScreen(page: 144, pageCount: 144, lastPageBottom: 0.2), 144);
    });
  });
}
