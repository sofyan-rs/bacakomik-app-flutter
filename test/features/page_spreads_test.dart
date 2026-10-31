import 'package:bacakomik_app/features/reader/presentation/page_spreads.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the cover is alone, then pages go two by two', () {
    const spreads = PageSpreads(6);
    expect(spreads.count, 4);
    expect(
      [for (var s = 0; s < spreads.count; s++) spreads.pages(s)],
      [
        [0],
        [1, 2],
        [3, 4],
        [5],
      ],
    );
  });

  test('an even count leaves no page alone at the end', () {
    const spreads = PageSpreads(5);
    expect(spreads.count, 3);
    expect(spreads.pages(2), [3, 4]);
  });

  test('a page maps to its spread, past the end to the end card', () {
    const spreads = PageSpreads(6);
    expect(
      [for (var p = 0; p < 6; p++) spreads.spreadOf(p)],
      [0, 1, 1, 2, 2, 3],
    );
    expect(spreads.spreadOf(6), spreads.count);
  });

  test('a spread is read once its last page is', () {
    const spreads = PageSpreads(6);
    expect(spreads.last(0), 0);
    expect(spreads.last(1), 2);
    expect(spreads.last(3), 5);
  });

  test('stepping back lands in the spread before', () {
    const spreads = PageSpreads(6);
    expect(spreads.spreadOf(spreads.pageBefore(4)), 1);
    expect(spreads.spreadOf(spreads.pageBefore(2)), 0);
    expect(spreads.pageBefore(0), -1);
    expect(spreads.spreadOf(spreads.pageBefore(6)), 3);
  });

  test('one page and none', () {
    expect(const PageSpreads(1).count, 1);
    expect(const PageSpreads(1).pages(0), [0]);
    expect(const PageSpreads(0).count, 0);
  });
}
