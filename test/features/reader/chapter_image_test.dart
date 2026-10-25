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
}
