import 'package:bacakomik_app/app/lazy_indexed_stack.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Counts how often each tab's state is created.
final _created = <int>[];

class _Tab extends StatefulWidget {
  const _Tab(this.index);

  final int index;

  @override
  State<_Tab> createState() => _TabState();
}

class _TabState extends State<_Tab> {
  var taps = 0;

  @override
  void initState() {
    super.initState();
    _created.add(widget.index);
  }

  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: () => setState(() => taps++),
    child: Text('tab ${widget.index}: $taps'),
  );
}

Widget _app(int index) => MaterialApp(
  home: LazyIndexedStack(
    index: index,
    itemCount: 5,
    itemBuilder: (_, i) => _Tab(i),
  ),
);

void main() {
  setUp(_created.clear);

  testWidgets('builds a tab on its first visit, then keeps it', (tester) async {
    await tester.pumpWidget(_app(0));
    expect(_created, [0]);

    await tester.tap(find.text('tab 0: 0'));
    await tester.pump();

    await tester.pumpWidget(_app(2));
    expect(_created, [0, 2]);

    await tester.pumpWidget(_app(0));
    await tester.pumpWidget(_app(2));
    // Neither was rebuilt from scratch: tab 0 kept its taps.
    expect(_created, [0, 2]);
    expect(find.text('tab 0: 1', skipOffstage: false), findsOneWidget);
    expect(find.text('tab 1: 0', skipOffstage: false), findsNothing);
  });
}
