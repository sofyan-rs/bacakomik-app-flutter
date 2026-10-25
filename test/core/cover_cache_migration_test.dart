import 'dart:typed_data';

import 'package:bacakomik_app/core/network/cover_cache_migration.dart';
import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

import '../helpers/hive.dart';

const _fs = LocalFileSystem();

/// Files on disk by URL; [putFile] calls are recorded.
class _MemoryCache extends Fake implements BaseCacheManager {
  _MemoryCache(this.dir);

  final Directory dir;
  final files = <String, ({File file, DateTime validTill})>{};
  final puts =
      <
        ({
          String url,
          List<int> bytes,
          String? eTag,
          Duration maxAge,
          String extension,
        })
      >[];

  Future<void> add(String url, String name, List<int> bytes, DateTime till) {
    final file = _fs.file('${dir.path}/$name');
    files[url] = (file: file, validTill: till);
    return file.writeAsBytes(bytes);
  }

  @override
  Future<FileInfo?> getFileFromCache(
    String key, {
    bool ignoreMemCache = false,
  }) async {
    final entry = files[key];
    if (entry == null) return null;
    return FileInfo(entry.file, FileSource.Cache, entry.validTill, key);
  }

  @override
  Future<File> putFile(
    String url,
    Uint8List fileBytes, {
    String? key,
    String? eTag,
    Duration maxAge = const Duration(days: 30),
    String fileExtension = 'file',
  }) async {
    puts.add((
      url: url,
      bytes: fileBytes,
      eTag: eTag,
      maxAge: maxAge,
      extension: fileExtension,
    ));
    final file = _fs.file('${dir.path}/put-${puts.length}.$fileExtension');
    await file.writeAsBytes(fileBytes);
    files[url] = (file: file, validTill: DateTime.now().add(maxAge));
    return file;
  }
}

void main() {
  late Future<void> Function() tearDownHive;
  late Directory dir;
  late Box<String> flags;
  late _MemoryCache pages;
  late _MemoryCache covers;

  setUp(() async {
    tearDownHive = await setUpTempHive();
    dir = await _fs.systemTempDirectory.createTemp('bacakomik_covers_');
    await _fs.directory('${dir.path}/pages').create();
    await _fs.directory('${dir.path}/covers').create();
    flags = await Hive.openBox<String>('settings');
    pages = _MemoryCache(_fs.directory('${dir.path}/pages'));
    covers = _MemoryCache(_fs.directory('${dir.path}/covers'));
  });

  tearDown(() async {
    await tearDownHive();
    await dir.delete(recursive: true);
  });

  CoverCacheMigration migration(List<String> urls) => CoverCacheMigration(
    pages: pages,
    covers: covers,
    flags: flags,
    coverUrls: () => urls,
    eTagOf: (url) async => 'etag:$url',
    batchSize: 2,
  );

  test('copies cached covers with their bytes, extension, eTag and expiry, '
      'skips missing ones', () async {
    final till = DateTime.now().add(const Duration(days: 5));
    await pages.add('https://a.test/1.webp', 'x1.webp', [1, 2, 3], till);
    await pages.add('https://a.test/2', 'x2.png', [4, 5], till);
    await pages.add('https://a.test/old.jpg', 'x3.jpg', [
      6,
    ], DateTime.now().subtract(const Duration(days: 1)));

    final copied = await migration([
      'https://a.test/1.webp',
      'https://a.test/missing.jpg',
      'https://a.test/2',
      'https://a.test/1.webp',
      'https://a.test/old.jpg',
      '',
    ]).run();

    expect(copied, 3);
    expect(covers.puts.map((p) => p.url), [
      'https://a.test/1.webp',
      'https://a.test/2',
      'https://a.test/old.jpg',
    ]);
    final first = covers.puts.first;
    expect(first.bytes, [1, 2, 3]);
    expect(first.extension, 'webp');
    expect(first.eTag, 'etag:https://a.test/1.webp');
    expect(first.maxAge.inDays, 4); // A bit under five days are left.
    expect(covers.puts[1].extension, 'png');
    expect(covers.puts[2].maxAge, Duration.zero);
    // The page cache keeps its copies.
    expect(pages.files, hasLength(3));
    expect(flags.get(CoverCacheMigration.doneKey), isNotNull);
  });

  test('runs once', () async {
    final till = DateTime.now().add(const Duration(days: 5));
    await pages.add('https://a.test/1.jpg', 'x1.jpg', [1], till);

    expect(await migration(['https://a.test/1.jpg']).run(), 1);
    await pages.add('https://a.test/2.jpg', 'x2.jpg', [2], till);
    final again = migration(['https://a.test/1.jpg', 'https://a.test/2.jpg']);

    expect(again.done, isTrue);
    expect(await again.run(), 0);
    expect(covers.puts, hasLength(1));
  });

  test('leaves covers already in the cover cache alone', () async {
    final till = DateTime.now().add(const Duration(days: 5));
    await pages.add('https://a.test/1.jpg', 'x1.jpg', [1], till);
    await covers.add('https://a.test/1.jpg', 'new.jpg', [9], till);

    expect(await migration(['https://a.test/1.jpg']).run(), 0);
    expect(covers.puts, isEmpty);
    expect(await covers.files['https://a.test/1.jpg']!.file.readAsBytes(), [9]);
  });
}
