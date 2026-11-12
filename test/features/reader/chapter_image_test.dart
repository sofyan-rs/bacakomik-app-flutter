import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:yoru/core/constants/texts.dart';
import 'package:yoru/core/theme/dotline_theme.dart';
import 'package:yoru/core/utils/image_support.dart';
import 'package:yoru/features/reader/presentation/widgets/chapter_image.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _FailingCache extends Mock implements BaseCacheManager {}

void main() {
  // Answered once, outside the tests' fake time: a failed page asks for it,
  // and an answer first asked for inside one test would never come.
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await avifSupported();
  });

  testWidgets('a failed page retries in place and requests the image again', (
    tester,
  ) async {
    const url = 'https://example.com/1.jpg';
    final cache = _FailingCache();
    var requests = 0;
    when(
      () => cache.getFileStream(
        any(),
        key: any(named: 'key'),
        headers: any(named: 'headers'),
        withProgress: any(named: 'withProgress'),
      ),
    ).thenAnswer((_) {
      requests++;
      return Stream.error(const HttpException('503'));
    });
    when(() => cache.removeFile(any())).thenAnswer((_) async {});

    await tester.pumpWidget(
      MaterialApp(
        theme: DotlineThemes.dark,
        home: Scaffold(
          body: SingleChildScrollView(
            child: ChapterImg(chapterImage: url, page: 3, cacheManager: cache),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(requests, 1);
    expect(find.text(AppText.pageNotLoaded), findsOneWidget);
    final failedHeight = tester.getSize(find.byType(ChapterImg)).height;

    await tester.tap(find.text(AppText.retry));
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(requests, 2);
    verify(() => cache.removeFile(url)).called(1);
    expect(find.text(AppText.pageNotLoaded), findsOneWidget);
    expect(tester.getSize(find.byType(ChapterImg)).height, failedHeight);
  });

  testWidgets('an AVIF page the device cannot show says so, with the site', (
    tester,
  ) async {
    // The test engine, like Android 11 and the desktops, has no AVIF decoder.
    expect(avifSupportedNow, isFalse);
    final dir = await tester.runAsync(
      () => Directory.systemTemp.createTemp('avif'),
    );
    addTearDown(() => dir!.delete(recursive: true));
    final file = File('${dir!.path}/1.avif');
    // ftyp box, brand avis (an image sequence, as VoraToon's credit page).
    await tester.runAsync(
      () => file.writeAsBytes([
        0, 0, 0, 0x1c, ...'ftypavis'.codeUnits, 0, 0, 0, 0, //
        ...'avisavifmsf1'.codeUnits,
      ]),
    );
    var opened = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: DotlineThemes.dark,
        home: Scaffold(
          body: SingleChildScrollView(
            child: ChapterImg(
              chapterImage: file.path,
              isFile: true,
              page: 1,
              onOpenWeb: () => opened++,
            ),
          ),
        ),
      ),
    );
    for (var i = 0; i < 20; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(Duration(milliseconds: 100)),
      );
      await tester.pump();
    }

    expect(find.text(AppText.avifNotSupported), findsOneWidget);
    await tester.tap(find.text(AppText.openInBrowser));
    expect(opened, 1);
  });

  test('isAvif reads the ftyp brand', () {
    List<int> head(String brand) => [0, 0, 0, 0x1c, ...'ftyp$brand'.codeUnits];
    expect(isAvif(Uint8List.fromList(head('avif'))), isTrue);
    expect(isAvif(Uint8List.fromList(head('avis'))), isTrue);
    expect(isAvif(Uint8List.fromList(head('heic'))), isFalse);
    expect(isAvif(Uint8List.fromList([0xFF, 0xD8, 0xFF])), isFalse);
  });

  group('page height', () {
    Widget page(String image, {bool isFile = false, bool load = true}) =>
        MaterialApp(
          theme: DotlineThemes.dark,
          home: Scaffold(
            body: SingleChildScrollView(
              child: SizedBox(
                width: 400,
                child: ChapterImg(
                  chapterImage: image,
                  page: 1,
                  isFile: isFile,
                  load: load,
                ),
              ),
            ),
          ),
        );

    testWidgets('a page seen before keeps its height while it loads', (
      tester,
    ) async {
      await tester.pumpWidget(page('https://example.com/new.jpg', load: false));
      expect(tester.getSize(find.byType(ChapterImg)).height, 480);

      rememberPageAspect('https://example.com/seen.jpg', const Size(10, 30));
      await tester.pumpWidget(
        page('https://example.com/seen.jpg', load: false),
      );
      expect(tester.getSize(find.byType(ChapterImg)).height, 1200);
    });

    testWidgets('the height is learnt from the image shown', (tester) async {
      // 1 x 2 pixels.
      final file = File('${Directory.systemTemp.createTempSync().path}/p.png')
        ..writeAsBytesSync(
          base64Decode(
            'iVBORw0KGgoAAAANSUhEUgAAAAEAAAACCAIAAAAW4yFwAAAADklEQVR4nGP4z8DA'
            'AMQACf4B/4PiLjgAAAAASUVORK5CYII=',
          ),
        );
      await tester.runAsync(() async {
        await tester.pumpWidget(page(file.path, isFile: true));
        for (var i = 0; i < 20 && pageAspectOf(file.path) == null; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 100));
          await tester.pump();
        }
      });
      expect(pageAspectOf(file.path), 2);
      expect(tester.getSize(find.byType(ChapterImg)).height, 800);
    });
  });
}
