import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:yoru/core/network/doh.dart';

/// DNS over HTTPS for WebViews on every platform, and for NSURLSession
/// (extensions' requests) on iOS: dart:io's [DohHttpOverrides] reaches
/// neither. Neither takes a resolver, but both take a proxy: while DoH is
/// on, they go through [WebViewDnsProxy], a local HTTP proxy that looks
/// hosts up with [Doh]. TLS still runs between the app and the site.
///
/// Android, iOS 17+, macOS 14+ and Linux switch the proxy on and off with
/// [ProxyController]. WebView2 (Windows) takes a proxy only when its
/// [environment] is created, so there the proxy always runs and follows
/// [Doh] itself: the system DNS while DoH is off.
abstract final class WebViewDns {
  static bool get supported => !kIsWeb;

  static WebViewDnsProxy? _proxy;
  static AppLifecycleListener? _lifecycle;

  /// Routes WebViews through the proxy when [on], directly otherwise.
  /// Fails quietly where the system has no proxy setting (iOS 16, macOS 13
  /// and older, Android WebViews without proxy override), leaving WebViews
  /// on the system DNS.
  static Future<void> apply({required bool on}) async {
    if (!supported || Platform.isWindows) return;
    if (!on) return _stop();
    if (_proxy != null) return;
    try {
      final proxy = await WebViewDnsProxy.start();
      _proxy = proxy;
      await _setOverride(proxy.port);
      _lifecycle ??= AppLifecycleListener(onResume: _checkAlive);
    } catch (e) {
      debugPrint('WebView DNS not set: $e');
      await _stop();
    }
  }

  /// Sessions made after this call use the proxy (`SessionProxy` in
  /// AppDelegate.swift); ones made before stay direct.
  static const _sessions = MethodChannel('yoru/session_proxy');

  static Future<void> _setOverride(int port) async {
    await ProxyController.instance().setProxyOverride(
      settings: ProxySettings(
        proxyRules: [ProxyRule(url: 'http://127.0.0.1:$port')],
      ),
    );
    await _setSessionPort(port);
  }

  static Future<void> _setSessionPort(int? port) async {
    if (!Platform.isIOS) return;
    try {
      await _sessions.invokeMethod<bool>('setPort', port);
    } catch (e) {
      debugPrint('Session proxy not set: $e');
    }
  }

  static Future<void> _stop() async {
    final proxy = _proxy;
    _proxy = null;
    _lifecycle?.dispose();
    _lifecycle = null;
    if (proxy == null) return;
    await proxy.close();
    await _setSessionPort(null);
    try {
      await ProxyController.instance().clearProxyOverride();
    } catch (e) {
      debugPrint('WebView proxy not cleared: $e');
    }
  }

  static Future<WebViewEnvironment?>? _environment;

  /// The WebView2 environment every WebView and [CookieManager] on Windows
  /// must use (two environments on one data folder with other arguments
  /// fail): it sends requests through the proxy. Null elsewhere, and when
  /// it cannot be made (the default environment, on the system DNS).
  static Future<WebViewEnvironment?> environment() =>
      _environment ??= _createEnvironment();

  static Future<WebViewEnvironment?> _createEnvironment() async {
    if (kIsWeb || !Platform.isWindows) return null;
    WebViewDnsProxy? proxy;
    try {
      proxy = await WebViewDnsProxy.start();
      final environment = await WebViewEnvironment.create(
        settings: WebViewEnvironmentSettings(
          additionalBrowserArguments:
              '--proxy-server=http://127.0.0.1:${proxy.port}',
        ),
      );
      _proxy = proxy;
      return environment;
    } catch (e) {
      debugPrint('WebView2 environment not made: $e');
      await proxy?.close();
      return null;
    }
  }

  /// The cookie manager of the WebViews (of [environment] on Windows).
  static Future<CookieManager> cookies() async =>
      CookieManager.instance(webViewEnvironment: await environment());

  /// iOS may take a suspended app's listening socket away: a new proxy
  /// replaces it when it no longer answers, on the same port when free
  /// (sessions keep the port they were made with).
  static Future<void> _checkAlive() async {
    final proxy = _proxy;
    if (proxy == null || await proxy.answers()) return;
    _proxy = null;
    final port = proxy.port;
    await proxy.close();
    try {
      WebViewDnsProxy fresh;
      try {
        fresh = await WebViewDnsProxy.start(port: port);
      } on SocketException {
        fresh = await WebViewDnsProxy.start();
      }
      _proxy = fresh;
      if (fresh.port != port) await _setOverride(fresh.port);
    } catch (e) {
      debugPrint('WebView DNS not restored: $e');
    }
  }
}

/// An HTTP proxy on 127.0.0.1 that connects to sites through [connect]
/// ([connectViaDoh] by default). Takes `CONNECT host:port` (HTTPS, and
/// WebKit's plain HTTP) and absolute-form requests (`GET http://…`).
class WebViewDnsProxy {
  WebViewDnsProxy._(this._server, this._connect) {
    _server.listen(_handle, onError: (Object e) => debugPrint('Proxy: $e'));
  }

  /// Listens on [port], any free one when 0.
  static Future<WebViewDnsProxy> start({
    int port = 0,
    Future<Socket> Function(String host, int port) connect = connectViaDoh,
  }) async {
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, port);
    return WebViewDnsProxy._(server, connect);
  }

  final ServerSocket _server;
  late final int port = _server.port;
  final Future<Socket> Function(String host, int port) _connect;
  final _open = <Socket>{};

  Future<bool> answers() async {
    try {
      final socket = await Socket.connect(
        InternetAddress.loopbackIPv4,
        port,
        timeout: const Duration(seconds: 1),
      );
      socket.destroy();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> close() async {
    await _server.close();
    for (final socket in _open.toList()) {
      socket.destroy();
    }
    _open.clear();
  }

  /// The longest request head taken before the connection is dropped.
  static const _maxHead = 64 * 1024;

  void _handle(Socket client) {
    _open.add(client);
    client.done.catchError((Object _) {}).whenComplete(() {
      _open.remove(client);
    });
    final head = BytesBuilder(copy: false);
    Socket? upstream;
    var parsed = false;
    late final StreamSubscription<Uint8List> sub;
    sub = client.listen(
      (data) {
        if (upstream != null) {
          _send(upstream!, data, client);
          return;
        }
        head.add(data);
        if (parsed) return;
        final bytes = head.toBytes();
        final end = _headEnd(bytes);
        if (end < 0) {
          if (bytes.length > _maxHead) client.destroy();
          return;
        }
        parsed = true;
        sub.pause();
        _tunnel(client, bytes, end).then(
          (socket) {
            upstream = socket;
            sub.resume();
          },
          onError: (Object e) {
            debugPrint('Proxy: $e');
            _reply(client, '502 Bad Gateway');
          },
        );
      },
      onDone: () => upstream?.close().catchError((Object _) {}),
      onError: (Object _) => upstream?.destroy(),
      cancelOnError: true,
    );
  }

  /// Connects to the host the request names and forwards what came after
  /// the head; pipes the site's answer back to [client].
  Future<Socket> _tunnel(Socket client, Uint8List bytes, int end) async {
    final lines = latin1.decode(bytes.sublist(0, end)).split('\r\n');
    final request = lines.first.split(' ');
    if (request.length != 3) throw FormatException('Bad request', lines.first);
    final [method, target, version] = request;
    final rest = bytes.sublist(end + 4);
    late final Socket upstream;
    if (method.toUpperCase() == 'CONNECT') {
      final (host, port) = _hostPort(target, 443);
      upstream = await _connect(host, port);
      client.add(latin1.encode('HTTP/1.1 200 Connection Established\r\n\r\n'));
      if (rest.isNotEmpty) upstream.add(rest);
    } else {
      final uri = Uri.parse(target);
      if (!uri.isScheme('http') || uri.host.isEmpty) {
        throw FormatException('Not a proxy request', target);
      }
      upstream = await _connect(uri.host, uri.port);
      // One request per connection: a later one may name another host.
      final headers = lines.skip(1).where((l) => l.isNotEmpty).where((l) {
        final name = l.split(':').first.trim().toLowerCase();
        return name != 'connection' && name != 'proxy-connection';
      }).toList();
      final path = uri.hasQuery ? '${uri.path}?${uri.query}' : uri.path;
      final origin = path.isEmpty ? '/' : path;
      upstream
        ..add(
          latin1.encode(
            [
              '$method $origin $version',
              ...headers,
              'Connection: close',
              '',
              '',
            ].join('\r\n'),
          ),
        )
        ..add(rest);
    }
    _open.add(upstream);
    upstream.done.catchError((Object _) {}).whenComplete(() {
      _open.remove(upstream);
    });
    upstream.listen(
      (data) => _send(client, data, upstream),
      onDone: () => client.close().catchError((Object _) {}),
      onError: (Object _) => client.destroy(),
      cancelOnError: true,
    );
    return upstream;
  }

  static void _send(Socket to, Uint8List data, Socket other) {
    try {
      to.add(data);
    } catch (_) {
      other.destroy();
    }
  }

  static void _reply(Socket client, String status) {
    try {
      client
        ..add(latin1.encode('HTTP/1.1 $status\r\nConnection: close\r\n\r\n'))
        ..close().catchError((Object _) {});
    } catch (_) {
      client.destroy();
    }
  }

  /// `host:port`, `[v6]:port` or a bare host.
  static (String, int) _hostPort(String target, int fallback) {
    final uri = Uri.parse('//$target');
    if (uri.host.isEmpty) throw FormatException('Bad host', target);
    return (uri.host, uri.hasPort ? uri.port : fallback);
  }

  /// Index of the `\r\n\r\n` that ends the head, or -1.
  static int _headEnd(Uint8List b) {
    for (var i = 0; i + 3 < b.length; i++) {
      if (b[i] == 13 && b[i + 1] == 10 && b[i + 2] == 13 && b[i + 3] == 10) {
        return i;
      }
    }
    return -1;
  }
}
