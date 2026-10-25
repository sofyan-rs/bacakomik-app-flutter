import 'dart:convert';
import 'dart:io';

import 'package:bacakomik_app/core/source/extension_bridge.dart';
import 'package:bacakomik_app/core/source/headless_pages.dart';
import 'package:cronet_http/cronet_http.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart' as webview;

/// Disk cache for chapter pages: the reader, its prefetch, page downloads
/// from blocked hosts. Clear cache empties it. Covers are in
/// [coverImageCache].
///
/// On Android it downloads through Cronet (Chrome's network stack) with the
/// headers Chrome sends for an image, plus the cookies the WebViews got for
/// the host (e.g. Cloudflare's cf_clearance): some image hosts (WestManga)
/// block anything that does not look like a browser. Hosts whose Cloudflare
/// rules still turn that away (WestManga's chapter pages) are fetched from
/// inside the site in a hidden WebView. It keeps [DefaultCacheManager]'s
/// key, so images cached before stay.
///
/// About ten chapters' worth of pages; ones not seen for two weeks go.
final CacheManager comicImageCache = CacheManager(
  Config(
    DefaultCacheManager.key,
    maxNrOfCacheObjects: 500,
    stalePeriod: const Duration(days: 14),
    fileService: _fileService,
  ),
);

/// Disk cache for covers, kept apart from [comicImageCache] so a large
/// library's covers are not pushed out by chapter pages and survive Clear
/// cache. Same downloader as [comicImageCache].
final CacheManager coverImageCache = CacheManager(
  Config(
    coverImageCacheKey,
    maxNrOfCacheObjects: 5000,
    stalePeriod: const Duration(days: 365),
    fileService: _fileService,
  ),
);

const coverImageCacheKey = 'bacakomikCovers';

final _fileService = _BrowserLikeFileService();

/// Whether [url]'s host turns away requests that do not come from inside
/// the site (see [comicImageCache]); the image caches get its images
/// anyway, other downloaders do not.
Future<bool> imageHostBlocks(String url, {Map<String, String>? headers}) =>
    _fileService.blocks(Uri.parse(url), headers);

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

  /// Cookie header per host, briefly cached: one platform call per host.
  final _cookies = <String, ({String header, DateTime at})>{};

  Future<String> _cookieHeader(Uri url) async {
    final cached = _cookies[url.host];
    if (cached != null &&
        DateTime.now().difference(cached.at) < const Duration(seconds: 30)) {
      return cached.header;
    }
    var header = '';
    try {
      final cookies = await webview.CookieManager.instance().getCookies(
        url: webview.WebUri.uri(url),
      );
      header = [for (final c in cookies) '${c.name}=${c.value}'].join('; ');
    } catch (_) {
      // No WebView on this platform.
    }
    _cookies[url.host] = (header: header, at: DateTime.now());
    return header;
  }

  @override
  Future<FileServiceResponse> get(
    String url, {
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse(url);
    if (_inPage(uri.host)) return _getInPage(uri, headers);
    final response = await _getDirect(uri, headers);
    if (!_isBlocked(uri, response)) return response;
    await response.content.drain<void>();
    return _getInPage(uri, headers);
  }

  /// See [imageHostBlocks].
  Future<bool> blocks(Uri url, Map<String, String>? headers) async {
    if (_inPage(url.host)) return true;
    final response = await _getDirect(url, headers);
    await response.content.drain<void>();
    return _isBlocked(url, response);
  }

  Future<FileServiceResponse> _getDirect(
    Uri url,
    Map<String, String>? headers,
  ) async {
    final cookie = await _cookieHeader(url);
    return _inner.get(
      url.toString(),
      headers: {
        ..._imageHeaders,
        if (cookie.isNotEmpty) 'Cookie': cookie,
        ...?headers,
      },
    );
  }

  /// Whether [response] is a block the WebView can get past; remembers
  /// [url]'s host when it is.
  bool _isBlocked(Uri url, FileServiceResponse response) {
    if (!_pages.available || !_blocked.contains(response.statusCode)) {
      return false;
    }
    _inPageSince[url.host] = DateTime.now();
    return true;
  }

  /// Statuses Cloudflare answers a blocked request with.
  static const _blocked = {403, 503};

  /// Hosts that answered [_blocked]: their images go through the WebView
  /// for a while without trying the direct request first.
  final _inPageSince = <String, DateTime>{};

  bool _inPage(String host) {
    final since = _inPageSince[host];
    return since != null &&
        DateTime.now().difference(since) < const Duration(minutes: 30);
  }

  late final _pages = _ImagePages();

  Future<FileServiceResponse> _getInPage(
    Uri url,
    Map<String, String>? headers,
  ) async {
    final referrer = headers?['Referer'] ?? headers?['referer'];
    final data = await _pages.run('image:${url.host}', '${url.origin}/', '''
const res = await fetch(${jsonEncode(url.toString())}, {
  credentials: 'include',
  ${referrer == null ? '' : 'referrer: ${jsonEncode(referrer)},'}
});
if (!res.ok) return { status: res.status };
const bytes = new Uint8Array(await res.arrayBuffer());
let s = '';
for (let i = 0; i < bytes.length; i += 0x8000) {
  s += String.fromCharCode.apply(null, bytes.subarray(i, i + 0x8000));
}
return { status: res.status, body: btoa(s), type: res.headers.get('content-type') };
''');
    final result = (data as Map?)?.cast<String, Object?>() ?? const {};
    final status = (result['status'] as num?)?.toInt() ?? 500;
    final body = result['body'] as String?;
    if (body == null) {
      throw HttpExceptionWithStatus(
        status,
        'Invalid statusCode: $status',
        uri: url,
      );
    }
    return _BytesResponse(base64Decode(body), url, result['type'] as String?);
  }

  @override
  int get concurrentFetches => _inner.concurrentFetches;
}

/// Hidden WebViews for [_BrowserLikeFileService]: one per image host.
class _ImagePages extends HeadlessPages {
  _ImagePages()
    : super(
        userAgent: ExtensionBridge.userAgent,
        // The WebView keeps its cookies; nothing else needs them.
        onCookies: (_, _, _) async {},
      );

  /// Hidden WebViews exist on Android only here.
  bool get available => !kIsWeb && Platform.isAndroid;
}

/// An image downloaded in a WebView.
class _BytesResponse implements FileServiceResponse {
  _BytesResponse(this._bytes, this._url, this._type);

  final Uint8List _bytes;
  final Uri _url;
  final String? _type;

  @override
  Stream<List<int>> get content => Stream.value(_bytes);

  @override
  int? get contentLength => _bytes.length;

  @override
  int get statusCode => 200;

  @override
  DateTime get validTill => DateTime.now().add(const Duration(days: 7));

  @override
  String? get eTag => null;

  @override
  String get fileExtension {
    final type = _type?.split(';').first.trim();
    if (type != null && type.startsWith('image/')) {
      return '.${type.substring(6).replaceAll('jpeg', 'jpg')}';
    }
    final path = _url.path;
    final dot = path.lastIndexOf('.');
    return dot > path.lastIndexOf('/') ? path.substring(dot) : '.jpg';
  }
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
