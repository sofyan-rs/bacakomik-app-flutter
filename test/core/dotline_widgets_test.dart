import 'package:bacakomik_app/core/presentation/widgets/dotline/dotline.dart';
import 'package:bacakomik_app/core/theme/dotline_theme.dart';
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
      matchesSemantics(value: '12 dari 24'),
    );
  });

  testWidgets('FloatingNavBar reports the tapped tab', (tester) async {
    int? tapped;
    await tester.pumpWidget(
      _wrap(
        FloatingNavBar(
          selectedIndex: 0,
          onSelected: (i) => tapped = i,
          items: const [
            FloatingNavItem(icon: LucideIcons300.house, label: 'Beranda'),
            FloatingNavItem(icon: LucideIcons300.compass, label: 'Jelajah'),
            FloatingNavItem(icon: LucideIcons300.history, label: 'Riwayat'),
          ],
        ),
      ),
    );

    await tester.tap(find.byIcon(LucideIcons300.history));
    expect(tapped, 2);
    expect(find.bySemanticsLabel('Jelajah'), findsOneWidget);
  });

  testWidgets('SegmentedControl reports the tapped value', (tester) async {
    String? changed;
    await tester.pumpWidget(
      _wrap(
        SegmentedControl<String>(
          selected: 'system',
          onChanged: (v) => changed = v,
          segments: const [
            Segment(value: 'system', label: 'Sistem'),
            Segment(value: 'light', label: 'Terang'),
            Segment(value: 'dark', label: 'Gelap'),
          ],
        ),
      ),
    );

    expect(find.text('SISTEM'), findsOneWidget);
    await tester.tap(find.text('GELAP'));
    expect(changed, 'dark');
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
            ScreenHeader(title: 'Jelajah', subtitle: '6 komik'),
            StatTile(value: '431', label: 'Chapter dibaca'),
            UpdateBadge(count: 3),
            NewBadge(label: 'Baru'),
          ],
        ),
      ),
    );
    expect(find.text('JELAJAH'), findsOneWidget);
    expect(find.text('+3'), findsOneWidget);
    expect(find.text('BARU'), findsOneWidget);
  });
}
