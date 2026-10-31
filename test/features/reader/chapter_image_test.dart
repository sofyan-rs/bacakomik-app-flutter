import 'dart:convert';
import 'dart:io';

import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:bacakomik_app/core/theme/dotline_theme.dart';
import 'package:bacakomik_app/features/reader/presentation/widgets/chapter_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _FailingCache extends Mock implements BaseCacheManager {}

void main() {
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
          await Future<void>.delayed(const Duration(milliseconds: 50));
          await tester.pump();
        }
      });
      expect(pageAspectOf(file.path), 2);
      expect(tester.getSize(find.byType(ChapterImg)).height, 800);
    });
  });
}
