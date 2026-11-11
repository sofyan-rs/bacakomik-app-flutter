import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:yoru/core/source/mihon_process_host.dart';

/// Runs a real Mihon extension through the desktop host, as the app does:
/// [ProcessMihonHost] starts it, inspects and installs the extension, lists
/// comics, opens one and fetches a cover and a page.
///
/// Needs a runtime (`desktop/mihon-host/gradlew :host:runtimeImage`) and an
/// extension jar, e.g. Keiyoushi's MangaPill:
///
/// ```
/// YORU_MIHON_RUNTIME=desktop/mihon-host/host/build/runtime/yoru-mihon-runtime
/// YORU_MIHON_TEST_EXT=path/to/tachiyomi-en.mangapill-v1.6.1.jar
/// flutter test integration_test/desktop_mihon_test.dart -d windows
/// ```
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final extension = Platform.environment['YORU_MIHON_TEST_EXT'];
  final runtime = Platform.environment['YORU_MIHON_RUNTIME'];

  testWidgets(
    'a Mihon extension lists, opens and reads a comic',
    (tester) async {
      await tester.runAsync(() async {
        final host = ProcessMihonHost.instance;
        final info = await host.handle('inspect', {'path': extension}) as Map;
        final pkg = info['pkg'] as String;
        // The repo's key in the app; here the one it is signed with.
        final signer = (info['signers'] as List).first as String;
        final sources = await host.handle('install', {
          'pkg': pkg,
          'apk': extension,
          'signer': signer,
        }) as List;
        final source = 'mihon-${(sources.first as Map)['id']}';
        Future<Object?> call(String method, List<Object?> args) =>
            host.handle('call', {
              'source': source.substring('mihon-'.length),
              'method': method,
              'args': args,
            });

        final page = await call('browse', [
          {'page': 1},
        ]) as Map;
        final items = page['items'] as List;
        expect(items, isNotEmpty);
        final first = items.first as Map;
        debugLog('browse: ${items.length} comics, first ${first['title']}');

        final cover = await host.image(first['cover'] as String);
        expect(cover.bytes.length, greaterThan(1000));

        final chapters = await call('chapters', [first['slug']]) as List;
        expect(chapters, isNotEmpty);
        final chapter = await call('chapter', [
          first['slug'],
          (chapters.last as Map)['number'],
        ]) as Map;
        final images = chapter['images'] as List;
        expect(images, isNotEmpty);
        final pageImage = await host.image(images.first as String);
        expect(pageImage.bytes.length, greaterThan(1000));
        debugLog(
          'chapters: ${chapters.length}, pages: ${images.length}, '
          'cover ${cover.bytes.length} B, page ${pageImage.bytes.length} B',
        );

        await host.handle('uninstall', {'pkg': pkg});
      });
    },
    skip: extension == null || runtime == null,
    timeout: const Timeout(Duration(minutes: 3)),
  );
}

// ignore: avoid_print
void debugLog(String line) => print('MIHON $line');
