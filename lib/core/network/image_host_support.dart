import 'dart:convert';
import 'dart:isolate';
import 'dart:typed_data';

/// Which image hosts get the WebView's cookies, and the cached `Cookie`
/// header for each.
///
/// Reading the WebView's cookies is a blocking CookieManager call on the
/// main thread (the first one also starts Chromium), so it is made only for
/// hosts that turned a request away once ([markNeeded]), and its result is
/// kept for [ttl] or until a request with it is turned away again
/// ([invalidate]).
class ImageHostCookies {
  ImageHostCookies(this._read, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  /// Cookies a WebView holds rarely change between two pages of a chapter;
  /// a new `cf_clearance` (a check passed in the WebView) is picked up after
  /// a block through [invalidate], so this can be long.
  static const ttl = Duration(minutes: 10);

  final Future<String> Function(Uri url) _read;
  final DateTime Function() _now;

  final _needed = <String>{};
  final _headers = <String, ({Future<String> header, DateTime at})>{};

  /// Whether [host]'s requests carry the WebView's cookies.
  bool needs(String host) => _needed.contains(host);

  /// Starts sending the WebView's cookies to [host]. False when it already
  /// got them.
  bool markNeeded(String host) => _needed.add(host);

  /// Forgets the cached header of [host], e.g. after a block with it.
  void invalidate(String host) => _headers.remove(host);

  /// The `Cookie` header for [url]: empty for hosts that do not need one.
  /// Requests at the same time share one read.
  Future<String> header(Uri url) {
    if (!needs(url.host)) return Future.value('');
    final cached = _headers[url.host];
    if (cached != null && _now().difference(cached.at) < ttl) {
      return cached.header;
    }
    final header = _read(url).then<String>(
      (header) => header,
      onError: (Object _) => '', // No WebView on this platform.
    );
    _headers[url.host] = (header: header, at: _now());
    return header;
  }
}

/// Bodies at least this long are decoded on another isolate: about 48 KB of
/// image. Below it, starting an isolate costs more than the decode.
const offThreadDecodeLength = 64 * 1024;

/// Decodes the base64 [body] of an image fetched in a WebView, off the main
/// thread when it is large.
Future<Uint8List> decodeImageBody(String body) async {
  if (body.length < offThreadDecodeLength) return base64Decode(body);
  // The bytes come back without a copy (Isolate.exit).
  return Isolate.run(() => base64Decode(body));
}

/// Headers that image hosts want with every image, from the installed
/// extensions' `imageHosts` and `imageHeaders`: e.g. VoraToon's
/// cdn.voratoon.com answers 403 without `Referer: https://voratoon.co/`.
///
/// Looked up by the image's host, so every image of the host gets them
/// (covers, chapter pages, downloads, saving) without the callers knowing
/// the source. Headers a caller passes win.
class ImageHostHeaders {
  var _rules = <({String host, Map<String, String> headers})>[];

  /// Replaces the rules: [hosts] and their [headers], one entry per
  /// extension. A host also covers its subdomains; when two extensions
  /// name the same host, the first wins.
  void update(
    Iterable<({List<String> hosts, Map<String, String> headers})> extensions,
  ) {
    _rules = [
      for (final e in extensions)
        if (e.headers.isNotEmpty)
          for (final host in e.hosts) (host: host, headers: e.headers),
    ];
  }

  /// Headers for an image from [host]; empty when no extension names it.
  /// The most specific rule (longest host) wins.
  Map<String, String> forHost(String host) {
    final h = host.toLowerCase();
    ({String host, Map<String, String> headers})? best;
    for (final rule in _rules) {
      final matches = h == rule.host || h.endsWith('.${rule.host}');
      if (matches && (best == null || rule.host.length > best.host.length)) {
        best = rule;
      }
    }
    return best?.headers ?? const {};
  }
}
