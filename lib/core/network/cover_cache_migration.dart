import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:hive_ce/hive.dart';

/// One-time copy of library covers from the page cache, where every image
/// used to be, into the cover cache, so they are not downloaded again.
///
/// Covers already in [covers] are left alone. Files stay in [pages] and age
/// out there. Covers shown before the copy reaches them are downloaded
/// again.
class CoverCacheMigration {
  CoverCacheMigration({
    required this.pages,
    required this.covers,
    required this.flags,
    required this.coverUrls,
    Future<String?> Function(String url)? eTagOf,
    this.batchSize = 20,
  }) : _eTagOf = eTagOf ?? _defaultETagOf(pages);

  /// Where covers were cached before (`comicImageCache`).
  final BaseCacheManager pages;

  /// Where covers go (`coverImageCache`).
  final BaseCacheManager covers;

  /// Holds the done flag under [doneKey].
  final Box<String> flags;

  /// Cover URLs of the library; read when the copy starts.
  final Iterable<String> Function() coverUrls;

  final int batchSize;

  final Future<String?> Function(String url) _eTagOf;

  static const doneKey = 'coverCacheMigrated';

  bool get done => flags.get(doneKey) != null;

  /// Copies the covers unless that was done before. Returns how many were
  /// copied. Errors of one file are skipped; the run is marked done at the
  /// end, so an interrupted one starts over (skipping covers copied).
  Future<int> run() async {
    if (done) return 0;
    final urls = {
      for (final url in coverUrls())
        if (url.startsWith('http')) url,
    }.toList();
    var copied = 0;
    for (var start = 0; start < urls.length; start += batchSize) {
      final end = (start + batchSize).clamp(0, urls.length);
      for (final url in urls.sublist(start, end)) {
        try {
          if (await _copy(url)) copied++;
        } catch (e) {
          debugPrint('Cover not copied to the cover cache: $url: $e');
        }
      }
      // Let frames through between batches.
      await Future<void>.delayed(Duration.zero);
    }
    await flags.put(doneKey, DateTime.now().toIso8601String());
    return copied;
  }

  Future<bool> _copy(String url) async {
    if (await covers.getFileFromCache(url) != null) return false;
    final cached = await pages.getFileFromCache(url);
    if (cached == null || !await cached.file.exists()) return false;
    final bytes = await cached.file.readAsBytes();
    final left = cached.validTill.difference(DateTime.now());
    await covers.putFile(
      url,
      bytes,
      eTag: await _eTagOf(url),
      // Same expiry as before: a stale cover is checked again when shown.
      maxAge: left.isNegative ? Duration.zero : left,
      fileExtension: _extension(cached.file.path),
    );
    return true;
  }

  static String _extension(String path) {
    final name = path.split(RegExp(r'[/\\]')).last;
    final dot = name.lastIndexOf('.');
    return dot < 0 || dot == name.length - 1 ? 'jpg' : name.substring(dot + 1);
  }

  static Future<String?> Function(String url) _defaultETagOf(
    BaseCacheManager pages,
  ) =>
      (url) async => pages is CacheManager
      ? (await pages.store.retrieveCacheData(url))?.eTag
      : null;
}
