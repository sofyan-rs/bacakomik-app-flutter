import 'package:yoru/core/presentation/widgets/dotline/dotline.dart';
import 'package:yoru/core/theme/dotline_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons_300.dart';

Widget _wrap(Widget child, {ThemeData? theme}) => MaterialApp(
  theme: theme ?? DotlineThemes.dark,
  home: Scaffold(body: Center(child: child)),
);

void main() {
  group('DotMeter.litDots', () {
    test('no progress lights nothing', () {
      expect(DotMeter.litDots(0, 24, 12), 0);
      expect(DotMeter.litDots(5, 0, 12), 0);
    });

    test('any progress lights at least one dot', () {
      expect(DotMeter.litDots(1, 500, 12), 1);
    });

    test('only a full total lights every dot', () {
      expect(DotMeter.litDots(499, 500, 12), 11);
      expect(DotMeter.litDots(500, 500, 12), 12);
    });

    test('rounds in between', () {
      expect(DotMeter.litDots(67, 88, 22), 17);
    });
  });

  testWidgets('DotMeter exposes progress to screen readers', (tester) async {
    await tester.pumpWidget(_wrap(const DotMeter(value: 12, total: 24)));
    expect(
      tester.getSemantics(find.byType(DotMeter)),
      matchesSemantics(value: '12 of 24'),
    );
  });

  test('FloatingNavBar end circles touch the track ends', () {
    final lefts = FloatingNavBar.circleLefts(300, 5);
    expect(lefts.first, 0);
    expect(lefts.last + 52, 300);
    expect(lefts[2], (300 - 52) / 2);
  });

  test('FloatingNavBar gap between circles equals the edge padding', () {
    final track = FloatingNavBar.widthFor(5) - 6 * 2;
    final lefts = FloatingNavBar.circleLefts(track, 5);
    expect(lefts[1] - lefts[0] - 52, 6);
  });

  testWidgets('FloatingNavBar reports the tapped tab', (tester) async {
    int? tapped;
    await tester.pumpWidget(
      _wrap(
        FloatingNavBar(
          selectedIndex: 0,
          onSelected: (i) => tapped = i,
          items: const [
            FloatingNavItem(icon: LucideIcons300.house, label: 'Home'),
            FloatingNavItem(icon: LucideIcons300.compass, label: 'Explore'),
            FloatingNavItem(icon: LucideIcons300.history, label: 'History'),
          ],
        ),
      ),
    );

    await tester.tap(find.byIcon(LucideIcons300.history));
    expect(tapped, 2);
    expect(find.bySemanticsLabel('Explore'), findsOneWidget);
  });

  testWidgets('FloatingNavBar as a rail stacks tabs vertically', (
    tester,
  ) async {
    int? tapped;
    await tester.pumpWidget(
      _wrap(
        FloatingNavBar(
          axis: Axis.vertical,
          selectedIndex: 0,
          onSelected: (i) => tapped = i,
          items: const [
            FloatingNavItem(icon: LucideIcons300.house, label: 'Home'),
            FloatingNavItem(icon: LucideIcons300.compass, label: 'Explore'),
            FloatingNavItem(icon: LucideIcons300.history, label: 'History'),
          ],
        ),
      ),
    );

    final house = tester.getCenter(find.byIcon(LucideIcons300.house));
    final history = tester.getCenter(find.byIcon(LucideIcons300.history));
    expect(history.dx, house.dx);
    expect(history.dy, greaterThan(house.dy));

    await tester.tap(find.byIcon(LucideIcons300.history));
    expect(tapped, 2);
  });

  testWidgets('SegmentedControl reports the tapped value', (tester) async {
    String? changed;
    await tester.pumpWidget(
      _wrap(
        SegmentedControl<String>(
          selected: 'system',
          onChanged: (v) => changed = v,
          segments: const [
            Segment(value: 'system', label: 'System'),
            Segment(value: 'light', label: 'Light'),
            Segment(value: 'dark', label: 'Dark'),
          ],
        ),
      ),
    );

    expect(find.text('SYSTEM'), findsOneWidget);
    await tester.tap(find.text('DARK'));
    expect(changed, 'dark');
  });

  testWidgets('DotButton while loading shows dots and ignores taps', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      _wrap(DotButton(label: 'Open', onTap: () => taps++, loading: true)),
    );
    expect(find.text('Open'), findsNothing);
    expect(find.byType(DotLoader), findsOneWidget);
    await tester.tap(find.byType(DotButton));
    expect(taps, 0);
  });

  testWidgets('FloatingNavBar selects the tab a drag ends on', (tester) async {
    final selected = <int>[];
    await tester.pumpWidget(
      _wrap(
        FloatingNavBar(
          selectedIndex: 0,
          onSelected: selected.add,
          items: const [
            FloatingNavItem(icon: LucideIcons300.house, label: 'Home'),
            FloatingNavItem(icon: LucideIcons300.compass, label: 'Explore'),
            FloatingNavItem(icon: LucideIcons300.history, label: 'History'),
          ],
        ),
      ),
    );

    final house = tester.getCenter(find.byIcon(LucideIcons300.house));
    final history = tester.getCenter(find.byIcon(LucideIcons300.history));
    final gesture = await tester.startGesture(house);
    for (var i = 1; i <= 10; i++) {
      await gesture.moveTo(Offset.lerp(house, history, i / 10)!);
      await tester.pump();
    }
    // Nothing is selected until the finger lifts.
    expect(selected, isEmpty);
    await gesture.up();
    await tester.pump();
    expect(selected, [2]);
  });

  testWidgets('SegmentedControl selects the segment a drag ends on', (
    tester,
  ) async {
    final changed = <String>[];
    await tester.pumpWidget(
      _wrap(
        SegmentedControl<String>(
          selected: 'system',
          onChanged: changed.add,
          segments: const [
            Segment(value: 'system', label: 'System'),
            Segment(value: 'light', label: 'Light'),
            Segment(value: 'dark', label: 'Dark'),
          ],
        ),
      ),
    );

    await tester.dragFrom(
      tester.getCenter(find.text('SYSTEM')),
      tester.getCenter(find.text('DARK')) -
          tester.getCenter(find.text('SYSTEM')),
    );
    await tester.pump();
    expect(changed, ['dark']);

    // A drag that ends back where it started changes nothing.
    changed.clear();
    final start = tester.getCenter(find.text('SYSTEM'));
    final gesture = await tester.startGesture(start);
    await gesture.moveBy(const Offset(200, 0));
    await tester.pump();
    await gesture.moveTo(start);
    await gesture.up();
    await tester.pump();
    expect(changed, isEmpty);
  });

  testWidgets('ScrollableTabs that fit select the tab a drag ends on', (
    tester,
  ) async {
    final changed = <String>[];
    await tester.pumpWidget(
      _wrap(
        ScrollableTabs<String>(
          selected: 'a',
          onChanged: changed.add,
          segments: const [
            Segment(value: 'a', label: 'All'),
            Segment(value: 'b', label: 'Reading'),
            Segment(value: 'c', label: 'Done'),
          ],
        ),
      ),
    );
    await tester.pump();

    final from = tester.getCenter(find.text('ALL'));
    final to = tester.getCenter(find.text('DONE'));
    await tester.dragFrom(from, to - from);
    await tester.pump();
    expect(changed, ['c']);
  });

  testWidgets('ScrollableTabs that overflow scroll on a drag', (tester) async {
    final changed = <String>[];
    await tester.pumpWidget(
      _wrap(
        ScrollableTabs<String>(
          selected: 's0',
          onChanged: changed.add,
          segments: [
            for (var i = 0; i < 12; i++)
              Segment(value: 's$i', label: 'Source number $i'),
          ],
        ),
      ),
    );
    await tester.pump();
    final scrollable = tester.state<ScrollableState>(
      find.descendant(
        of: find.byType(ScrollableTabs<String>),
        matching: find.byType(Scrollable),
      ),
    );
    expect(scrollable.position.maxScrollExtent, greaterThan(0));

    await tester.drag(find.text('SOURCE NUMBER 1'), const Offset(-300, 0));
    await tester.pumpAndSettle();
    expect(scrollable.position.pixels, greaterThan(0));
    // Scrolling picks no tab.
    expect(changed, isEmpty);
  });

  testWidgets('DotSwitch toggles and ignores taps when disabled', (
    tester,
  ) async {
    var value = false;
    await tester.pumpWidget(
      _wrap(DotSwitch(value: value, onChanged: (v) => value = v)),
    );
    await tester.tap(find.byType(DotSwitch));
    expect(value, isTrue);

    await tester.pumpWidget(
      _wrap(const DotSwitch(value: false, onChanged: null)),
    );
    await tester.tap(find.byType(DotSwitch));
    expect(value, isTrue);
  });

  testWidgets('DotChip shows a check only when selected', (tester) async {
    await tester.pumpWidget(_wrap(const DotChip(label: 'Action')));
    expect(find.text('ACTION'), findsOneWidget);
    expect(find.byIcon(LucideIcons300.check), findsNothing);

    await tester.pumpWidget(
      _wrap(const DotChip(label: 'Action', selected: true)),
    );
    expect(find.byIcon(LucideIcons300.check), findsOneWidget);
  });

  testWidgets('components render in the light theme', (tester) async {
    await tester.pumpWidget(
      _wrap(
        theme: DotlineThemes.light,
        const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScreenHeader(title: 'Explore', subtitle: '6 comics'),
            StatTile(value: '431', label: 'Chapter dibaca'),
            UpdateBadge(count: 3),
            NewBadge(label: 'New'),
          ],
        ),
      ),
    );
    expect(find.text('EXPLORE'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('NEW'), findsOneWidget);
  });
}
