import 'package:bacakomik_app/core/presentation/widgets/dotline/cover_hero.dart';
import 'package:bacakomik_app/core/theme/dotline_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A card as the lists build them: its own context makes the tag.
class _Card extends StatelessWidget {
  const _Card();

  @override
  Widget build(BuildContext context) {
    final tag = CoverHeroTag(context, '');
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => Scaffold(
            body: Hero(
              tag: tag,
              flightShuttleBuilder: CoverHero.shuttle,
              child: const SizedBox(width: 168, height: 252),
            ),
          ),
        ),
      ),
      child: SizedBox(
        width: 100,
        height: 150,
        child: CoverHero(
          tag: tag,
          child: const ColoredBox(color: Colors.red),
        ),
      ),
    );
  }
}

void main() {
  testWidgets('the same comic twice on a screen flies to its details', (
    tester,
  ) async {
    // Home shows a comic in two rows: same cover, same slug, two heroes.
    await tester.pumpWidget(
      MaterialApp(
        theme: DotlineThemes.dark,
        home: const Scaffold(body: Column(children: [_Card(), _Card()])),
      ),
    );

    await tester.tap(find.byType(_Card).last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);
    await tester.pumpAndSettle();

    Navigator.of(tester.element(find.byType(Hero).last)).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);
    await tester.pumpAndSettle();
    expect(find.byType(_Card), findsNWidgets(2));
  });

  testWidgets('tags are one per card, kept across rebuilds', (tester) async {
    late BuildContext a;
    late BuildContext b;
    await tester.pumpWidget(
      Column(
        children: [
          Builder(builder: (c) => SizedBox.shrink(key: Key('${a = c}'))),
          Builder(builder: (c) => SizedBox.shrink(key: Key('${b = c}'))),
        ],
      ),
    );
    expect(CoverHeroTag(a, 'x'), CoverHeroTag(a, 'x'));
    expect(CoverHeroTag(a, 'x'), isNot(CoverHeroTag(b, 'x')));
  });
}
