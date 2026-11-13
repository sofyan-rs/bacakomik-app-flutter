import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

/// A DNS over HTTPS server (RFC 8484).
class DohServer {
  const DohServer({
    required this.id,
    required this.name,
    required this.url,
    this.bootstrap = const [],
  });

  /// Stored in settings for a preset; a custom server stores its [url].
  final String id;
  final String name;

  /// [name] without the address in brackets, for the row in More.
  String get shortName => name.split(' (').first;

  /// The `…/dns-query` endpoint.
  final String url;

  /// IP addresses of [url]'s host, so the server is reached without asking
  /// the system DNS (which may be the one blocking sites). Empty for a
  /// custom server: its host is looked up the usual way.
  final List<String> bootstrap;

  /// The server for a stored setting: '' (off), a preset id, or a custom
  /// `https://` URL. Null when off or not a valid setting.
  static DohServer? fromSetting(String setting) {
    final value = setting.trim();
    if (value.isEmpty) return null;
    for (final preset in dohPresets) {
      if (preset.id == value) return preset;
    }
    final url = normalizeCustomUrl(value);
    if (url == null) return null;
    return DohServer(id: url, name: Uri.parse(url).host, url: url);
  }

  /// A typed server address as a DoH URL: `https://` is added when no
  /// scheme is given, and `/dns-query` when no path is. Null when it has no
  /// host or another scheme (DoH is HTTPS only), e.g. `http://…`.
  static String? normalizeCustomUrl(String input) {
    var value = input.trim();
    if (value.isEmpty) return null;
    if (!value.contains('://')) value = 'https://$value';
    final uri = Uri.tryParse(value);
    if (uri == null || !uri.isScheme('https') || uri.host.isEmpty) {
      return null;
    }
    final path = uri.path.isEmpty || uri.path == '/' ? '/dns-query' : uri.path;
    return uri.replace(path: path).toString();
  }

  /// Whether [url] can be a custom server ([normalizeCustomUrl] takes it).
  static bool isValidCustomUrl(String url) => normalizeCustomUrl(url) != null;
}

/// The servers offered in settings. All answer DoH over HTTP/1.1, which
/// dart:io needs; Quad9's only takes HTTP/2, so it can only be a custom one.
const dohPresets = [
  DohServer(
    id: 'cloudflare',
    name: 'Cloudflare (1.1.1.1)',
    url: 'https://cloudflare-dns.com/dns-query',
    bootstrap: ['1.1.1.1', '1.0.0.1', '2606:4700:4700::1111'],
  ),
  DohServer(
    id: 'google',
    name: 'Google (8.8.8.8)',
    url: 'https://dns.google/dns-query',
    bootstrap: ['8.8.8.8', '8.8.4.4', '2001:4860:4860::8888'],
  ),
  DohServer(
    id: 'adguard',
    name: 'AdGuard',
    url: 'https://dns.adguard-dns.com/dns-query',
    bootstrap: ['94.140.14.14', '94.140.15.15', '2a10:50c0::ad1:ff'],
  ),
];

/// Where the app's own HTTP requests (dart:io) look up hostnames. Set from
/// settings; null uses the system DNS. Android's Cronet is not covered, but
/// hosts it cannot reach go through dart:io ([DohFallback]); WebViews are,
/// through `WebViewDnsProxy`, and Mihon extensions on their side (see
/// docs/ARCHITECTURE.md).
abstract final class Doh {
  static DohResolver? _resolver;

  static DohResolver? get resolver => _resolver;

  /// Uses [server] from now on; null turns DoH off.
  static void use(DohServer? server) {
    if (server?.url == _resolver?.server.url) return;
    _resolver?.close();
    _resolver = server == null ? null : DohResolver(server);
  }
}

/// Resolves hostnames through one [DohServer], with a cache that keeps
/// answers for their TTL (30 s to 1 h).
class DohResolver {
  DohResolver(this.server, {this.send});

  final DohServer server;

  /// Sends a wire-format query and returns the answer; tests replace it.
  /// Null posts it to [server].
  final Future<Uint8List> Function(Uint8List query)? send;
  final _cache = <String, (DateTime, List<InternetAddress>)>{};
  final _pending = <String, Future<List<InternetAddress>>>{};
  HttpClient? _client;

  /// IPv4 addresses first, then IPv6. Throws [SocketException] when the
  /// name has none or the server cannot be reached.
  Future<List<InternetAddress>> lookup(String host) {
    final key = host.toLowerCase();
    final hit = _cache[key];
    if (hit != null && hit.$1.isAfter(DateTime.now())) {
      return Future.value(hit.$2);
    }
    // A block body: whenComplete waits for a returned future, and remove()
    // would return this one.
    return _pending[key] ??= _lookup(key).whenComplete(() {
      _pending.remove(key);
    });
  }

  Future<List<InternetAddress>> _lookup(String host) async {
    final v4Query = _query(host, dnsTypeA);
    // IPv6 is optional: its failure leaves the IPv4 answer.
    final v6Query = _query(
      host,
      dnsTypeAaaa,
    ).catchError((Object _) => const DnsAnswer([], 0));
    final v4 = await v4Query;
    final v6 = await v6Query;
    final addresses = [...v4.addresses, ...v6.addresses];
    if (addresses.isEmpty) {
      throw SocketException('DNS over HTTPS: no address for $host');
    }
    final ttl = [v4, v6]
        .where((a) => a.addresses.isNotEmpty)
        .map((a) => a.ttl)
        .reduce((a, b) => a < b ? a : b)
        .clamp(30, 3600);
    _cache[host] = (DateTime.now().add(Duration(seconds: ttl)), addresses);
    return addresses;
  }

  Future<DnsAnswer> _query(String host, int type) async {
    final query = encodeDnsQuery(host, type);
    final response = await (send ?? _post)(query);
    return parseDnsAnswer(response, type);
  }

  /// GET with the query in `?dns=` (RFC 8484 §4.1), which every server
  /// takes over HTTP/1.1, the only version dart:io speaks.
  Future<Uint8List> _post(Uint8List query) async {
    final client = _client ??= _rawClient(server);
    final base = Uri.parse(server.url);
    final dns = base64Url.encode(query).replaceAll('=', '');
    final request = await client.getUrl(
      base.replace(queryParameters: {...base.queryParameters, 'dns': dns}),
    );
    request.headers.set(HttpHeaders.acceptHeader, 'application/dns-message');
    final response = await request.close().timeout(const Duration(seconds: 10));
    final bytes = await response.fold<BytesBuilder>(
      BytesBuilder(copy: false),
      (b, chunk) => b..add(chunk),
    );
    if (response.statusCode != 200) {
      throw SocketException(
        'DNS over HTTPS: ${server.url} answered ${response.statusCode}',
      );
    }
    return bytes.takeBytes();
  }

  void close() {
    _client?.close(force: true);
    _client = null;
  }
}

/// A client for the DoH server itself: not routed through [Doh], and it
/// reaches a preset's host by its [DohServer.bootstrap] addresses.
HttpClient _rawClient(DohServer server) {
  final client = HttpOverrides.runWithHttpOverrides(
    HttpClient.new,
    _PlainOverrides(),
  )..connectionTimeout = const Duration(seconds: 10);
  if (server.bootstrap.isEmpty) return client;
  final addresses = server.bootstrap.map(InternetAddress.new).toList();
  client.connectionFactory = (uri, proxyHost, proxyPort) async {
    if (proxyHost != null) return Socket.startConnect(proxyHost, proxyPort!);
    return _connectTo(addresses, uri.host, uri.port, secure: true);
  };
  return client;
}

class _PlainOverrides extends HttpOverrides {}

/// Hosts Cronet (Android) could not reach while DoH was on. Cronet takes
/// no resolver, so the image cache and extensions' requests send those
/// again through dart:io, which [Doh] covers: a network whose DNS blocks
/// the site answers with no address or a block page's certificate. Other
/// hosts stay on Cronet, whose TLS Cloudflare lets through.
abstract final class DohFallback {
  /// How long a host skips Cronet after it failed.
  static const keep = Duration(minutes: 30);

  static final _since = <String, DateTime>{};

  /// Whether requests to [host] go through dart:io straight away: DoH is
  /// on and Cronet failed to reach the host in the last [keep].
  static bool skipsNative(String host) {
    if (Doh.resolver == null) return false;
    final since = _since[host];
    if (since == null) return false;
    if (DateTime.now().difference(since) < keep) return true;
    _since.remove(host);
    return false;
  }

  /// Whether [error] is Cronet failing to reach [host] (a `net::ERR_*`)
  /// while DoH is on, so the request should go again through dart:io;
  /// remembers the host when it is.
  static bool takes(String host, Object error) {
    if (Doh.resolver == null || !'$error'.contains('net::ERR_')) return false;
    _since[host] = DateTime.now();
    return true;
  }

  @visibleForTesting
  static void reset() => _since.clear();
}

/// Routes every dart:io [HttpClient] of the app through [Doh] when it is
/// on. Set once in main(); clients made before keep the system DNS.
class DohHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.connectionFactory = (uri, proxyHost, proxyPort) =>
        _connect(uri, proxyHost, proxyPort, context);
    return client;
  }
}

/// A plain TCP connection to [host]:[port], its name looked up through
/// [Doh] when it is on (the system DNS when off or when DoH fails).
Future<Socket> connectViaDoh(String host, int port) async {
  final task = await _connect(
    Uri(scheme: 'http', host: host, port: port),
    null,
    null,
    null,
  );
  return task.socket;
}

Future<ConnectionTask<Socket>> _connect(
  Uri uri,
  String? proxyHost,
  int? proxyPort,
  SecurityContext? context,
) async {
  // Through a proxy, HttpClient tunnels and secures the connection itself.
  if (proxyHost != null) return Socket.startConnect(proxyHost, proxyPort!);
  final secure = uri.isScheme('https');
  final host = uri.host;
  final port = uri.port;
  final resolver = Doh.resolver;
  if (resolver != null &&
      InternetAddress.tryParse(host) == null &&
      host != 'localhost') {
    try {
      final addresses = await resolver.lookup(host);
      return await _connectTo(
        addresses,
        host,
        port,
        secure: secure,
        context: context,
      );
    } on Exception catch (e) {
      // The DoH server is unreachable or has no answer: the system DNS
      // keeps the app working.
      debugPrint('$e; using the system DNS');
    }
  }
  return secure
      ? SecureSocket.startConnect(host, port, context: context)
      : Socket.startConnect(host, port);
}

/// Connects to the first of [addresses] that answers; with [secure], TLS
/// is set up for [host] (SNI and the certificate check use the name).
Future<ConnectionTask<Socket>> _connectTo(
  List<InternetAddress> addresses,
  String host,
  int port, {
  required bool secure,
  SecurityContext? context,
}) async {
  ConnectionTask<Socket>? current;
  var cancelled = false;
  Future<Socket> open() async {
    Object? error;
    for (final address in addresses) {
      if (cancelled) break;
      try {
        final task = current = await Socket.startConnect(address, port);
        final socket = await task.socket.timeout(const Duration(seconds: 15));
        if (!secure) return socket;
        return await SecureSocket.secure(socket, host: host, context: context);
      } catch (e) {
        error = e;
      }
    }
    throw error ?? SocketException('Connection to $host cancelled');
  }

  return ConnectionTask.fromSocket(open(), () {
    cancelled = true;
    current?.cancel();
  });
}

const dnsTypeA = 1;
const dnsTypeAaaa = 28;

/// Addresses of one type from a DNS answer, and their lowest TTL.
class DnsAnswer {
  const DnsAnswer(this.addresses, this.ttl);
  final List<InternetAddress> addresses;
  final int ttl;
}

/// A DNS query for [host] and [type] in wire format, id 0 (RFC 8484 §4.1).
@visibleForTesting
Uint8List encodeDnsQuery(String host, int type) {
  final b = BytesBuilder()..add([0, 0, 0x01, 0x00, 0, 1, 0, 0, 0, 0, 0, 0]);
  for (final label in host.split('.').where((l) => l.isNotEmpty)) {
    final bytes = utf8.encode(label);
    if (bytes.length > 63) throw ArgumentError('Label too long: $label');
    b
      ..addByte(bytes.length)
      ..add(bytes);
  }
  b.add([0, type >> 8, type & 0xff, 0, 1]);
  return b.takeBytes();
}

/// The [type] records of a wire-format DNS response. An empty answer for a
/// name that does not exist; throws [SocketException] for a server failure.
@visibleForTesting
DnsAnswer parseDnsAnswer(Uint8List m, int type) {
  if (m.length < 12) throw const SocketException('DNS answer too short');
  final data = ByteData.sublistView(m);
  final rcode = data.getUint16(2) & 0xf;
  if (rcode == 3) return const DnsAnswer([], 0);
  if (rcode != 0) throw SocketException('DNS answer code $rcode');
  final questions = data.getUint16(4);
  final answers = data.getUint16(6);
  var i = 12;
  int skipName(int at) {
    while (at < m.length) {
      final len = m[at];
      if (len == 0) return at + 1;
      if (len & 0xc0 == 0xc0) return at + 2;
      at += len + 1;
    }
    throw const SocketException('Bad name in DNS answer');
  }

  for (var q = 0; q < questions; q++) {
    i = skipName(i) + 4;
  }
  final addresses = <InternetAddress>[];
  var ttl = 3600;
  for (var a = 0; a < answers && i + 10 <= m.length; a++) {
    i = skipName(i);
    final rType = data.getUint16(i);
    final rTtl = data.getUint32(i + 4);
    final length = data.getUint16(i + 8);
    i += 10;
    if (i + length > m.length) break;
    final expected = type == dnsTypeA ? 4 : 16;
    if (rType == type && length == expected) {
      addresses.add(
        InternetAddress.fromRawAddress(
          Uint8List.fromList(m.sublist(i, i + length)),
        ),
      );
      if (rTtl < ttl) ttl = rTtl;
    }
    i += length;
  }
  return DnsAnswer(addresses, ttl);
}
