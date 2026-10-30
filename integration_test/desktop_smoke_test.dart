import 'dart:io';
import 'dart:ui' as ui;

import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:bacakomik_app/core/theme/dotline_tokens.dart';
import 'package:bacakomik_app/core/presentation/widgets/dotline/round_icon_button.dart';
import 'package:bacakomik_app/features/comic_detail/presentation/widgets/chapter_tile.dart';
import 'package:bacakomik_app/features/home/presentation/widgets/comic_slider_card.dart';
import 'package:bacakomik_app/features/reader/presentation/widgets/chapter_image.dart';
import 'package:bacakomik_app/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'data_isolation.dart';

import 'package:path_provider/path_provider.dart';

/// Walks home → comic → reader on a real build, against live sources, and
/// saves a screenshot of each step. Run on a desktop with
/// `flutter test integration_test/desktop_smoke_test.dart -d macos`.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('home, comic and reader load', (tester) async {
    await expectIsolatedData();
    app.main();
    await _waitFor(tester, find.byType(ComicSliderCard));
    await _shot(tester, 'home');

    await tester.tap(find.byType(ComicSliderCard).first);
    await _waitFor(tester, find.textContaining(' · Ch. '));
    await _shot(tester, 'comic');

    await tester.tap(find.textContaining(' · Ch. '));
    await _waitFor(tester, find.byType(ChapterImg));
    await _settle(tester, const Duration(seconds: 6));
    await _shot(tester, 'reader');
    expect(
      tester.getSize(find.byType(ChapterImg).first).width,
      lessThanOrEqualTo(DotSize.readerMaxWidth),
    );

    final before = _scrolled(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await _settle(tester, const Duration(seconds: 1));
    expect(_scrolled(tester), greaterThan(before));

    Navigator.of(tester.element(find.byType(ChapterImg).first)).pop();
    await _settle(tester, const Duration(seconds: 2));
    final tile = find.byType(ChapterTile).first;
    await tester.ensureVisible(tile);
    await tester.longPress(tile);
    await _settle(tester, const Duration(seconds: 1));
    await tester.tap(_button(AppText.download));
    await _settle(tester, const Duration(seconds: 25));
    await _shot(tester, 'download');

    await tester.tap(_button(AppText.openWebView));
    await _settle(tester, const Duration(seconds: 12));
    await _shot(tester, 'webview');
  });
}

/// How far the reader's lists have scrolled, together.
double _scrolled(WidgetTester tester) => tester
    .stateList<ScrollableState>(find.byType(Scrollable))
    .fold(0, (sum, s) => sum + s.position.pixels);

Finder _button(String label) => find.byWidgetPredicate(
  (w) => w is RoundIconButton && w.semanticLabel == label,
);

Future<void> _settle(WidgetTester tester, Duration duration) async {
  final end = DateTime.now().add(duration);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _waitFor(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 30),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 200));
    if (finder.evaluate().isNotEmpty) {
      await _settle(tester, const Duration(seconds: 2));
      return;
    }
  }
  await _shot(tester, 'timeout');
  throw TestFailure('Timed out waiting for $finder');
}

Future<void> _shot(WidgetTester tester, String name) async {
  await tester.runAsync(() async {
    final view = tester.binding.renderViews.first;
    final layer = view.debugLayer! as OffsetLayer;
    final image = await layer.toImage(view.paintBounds);
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/smoke_$name.png');
    await file.writeAsBytes(png!.buffer.asUint8List());
    // ignore: avoid_print
    print('SHOT $name ${file.path}');
  });
}
