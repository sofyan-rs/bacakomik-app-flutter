import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yoru/core/utils/utils.dart';

void main() {
  Future<Rect> showToast(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          snackBarTheme: const SnackBarThemeData(
            behavior: SnackBarBehavior.floating,
          ),
        ),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () =>
                  showSnackBar(context: context, message: 'Title copied'),
              child: const Text('show'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('show'));
    await tester.pumpAndSettle(const Duration(milliseconds: 300));
    // The SnackBar fills the width; its Material is the toast itself.
    return tester.getRect(
      find
          .descendant(
            of: find.byType(SnackBar),
            matching: find.byType(Material),
          )
          .first,
    );
  }

  testWidgets('a wide window shows the toast at the top center, 480 wide', (
    tester,
  ) async {
    final rect = await showToast(tester, const Size(1600, 1000));
    expect(rect.width, 480);
    expect(rect.center.dx, 800);
    expect(rect.top, lessThan(100));
  });

  testWidgets('a phone shows the toast at the bottom, full width', (
    tester,
  ) async {
    final rect = await showToast(tester, const Size(400, 800));
    expect(rect.width, greaterThan(350));
    expect(rect.bottom, greaterThan(700));
  });
}
