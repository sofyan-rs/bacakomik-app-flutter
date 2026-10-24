import 'dart:io';

import 'package:bacakomik_app/core/source/extension_bridge.dart';
import 'package:cronet_http/cronet_http.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Disk cache for covers and chapter pages, shared by every image widget,
/// the reader's prefetch and Clear cache.
///
/// On Android it downloads through Cronet (Chrome's network stack) with the
/// headers Chrome sends for an image: some image hosts (WestManga) block
/// anything that does not look like a browser. It keeps
/// [DefaultCacheManager]'s key, so images cached before stay.
final CacheManager comicImageCache = CacheManager(
  Config(DefaultCacheManager.key, fileService: _BrowserLikeFileService()),
);

class _BrowserLikeFileService extends FileService {
  _BrowserLikeFileService() : _inner = _httpFileService();

  final HttpFileService _inner;

  /// What Chrome on Android sends with an `<img>` request.
  static const _imageHeaders = {
    'Accept': 'image/avif,image/webp,image/apng,image/*,*/*;q=0.8',
    'Accept-Language': 'en-US,en;q=0.9,id;q=0.8',
    'sec-ch-ua': '"Chromium";v="141", "Not?A_Brand";v="8"',
    'sec-ch-ua-mobile': '?1',
    'sec-ch-ua-platform': '"Android"',
    'sec-fetch-dest': 'image',
    'sec-fetch-mode': 'no-cors',
    'sec-fetch-site': 'same-origin',
  };

  @override
  Future<FileServiceResponse> get(String url, {Map<String, String>? headers}) =>
      _inner.get(url, headers: {..._imageHeaders, ...?headers});

  @override
  int get concurrentFetches => _inner.concurrentFetches;
}

HttpFileService _httpFileService() {
  if (kIsWeb || !Platform.isAndroid) return HttpFileService();
  try {
    final engine = CronetEngine.build(
      cacheMode: CacheMode.disabled,
      userAgent: ExtensionBridge.userAgent,
    );
    return HttpFileService(httpClient: CronetClient.fromCronetEngine(engine));
  } catch (e) {
    // No Cronet provider (e.g. no Google Play services): plain dart:io.
    debugPrint('Image cache without Cronet: $e');
    return HttpFileService();
  }
}
