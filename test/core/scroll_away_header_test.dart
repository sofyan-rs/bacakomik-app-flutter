import 'package:bacakomik_app/core/presentation/widgets/dotline/scroll_away_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget screen({Object? showOn}) => MaterialApp(
    home: Scaffold(
      body: ScrollAwayHeader(
        showOn: showOn,
        header: const SizedBox(height: 100, child: Text('Header')),
        body: ListView(
          children: [
            for (var i = 0; i < 100; i++)
              SizedBox(height: 80, child: Text('$i')),
          ],
        ),
      ),
    ),
  );

  bool headerShown(WidgetTester tester) =>
      find.text('Header').hitTestable().evaluate().isNotEmpty;

  testWidgets('hides scrolling down and comes back scrolling up', (
    tester,
  ) async {
    await tester.pumpWidget(screen());
    expect(headerShown(tester), isTrue);

    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(headerShown(tester), isFalse);

    await tester.drag(find.byType(ListView), const Offset(0, 100));
    await tester.pumpAndSettle();
    expect(headerShown(tester), isTrue);
  });

  testWidgets('comes back when the body shows something else', (tester) async {
    // Bookmarks: another tab opened while the header was hidden.
    await tester.pumpWidget(screen(showOn: 'all'));
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(headerShown(tester), isFalse);

    await tester.pumpWidget(screen(showOn: 'reading'));
    await tester.pumpAndSettle();
    expect(headerShown(tester), isTrue);
  });
}
