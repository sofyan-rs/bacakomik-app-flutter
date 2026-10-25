import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:bacakomik_app/core/error/exceptions.dart';
import 'package:bacakomik_app/core/source/headless_pages.dart';
import 'package:bacakomik_app/core/storage/box_recovery.dart';
import 'package:bacakomik_app/core/storage/hive_boxes.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:injectable/injectable.dart';
import 'package:native_dio_adapter/native_dio_adapter.dart';
import 'package:path_provider/path_provider.dart';

/// Host side of the functions extensions call: `http.fetch`, `html.select`,
/// `storage.get/set`. Each extension gets its own cookie jar and storage
/// namespace.
@lazySingleton
class ExtensionBridge {
  ExtensionBridge(@Named(HiveBoxes.extensionStorage) this._storage);

  /// Chrome on Android; sites serve extensions what they serve the phone.
  static const userAgent =
      'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Mobile Safari/537.36';

  final Box<String> _storage;
  final _clients = <String, Future<Dio>>{};
  late final _pages = HeadlessPages(
    userAgent: userAgent,
    onCookies: saveCookies,
  );
  final _jars = <String, Future<PersistCookieJar>>{};

  Future<Object?> handle(String extensionId, String method, Object? args) =>
      switch (method) {
        'http.fetch' => _fetch(extensionId, (args as Map).cast()),
        'html.select' => select((args as List)[0] as String, args[1] as String),
        'storage.get' => Future.value(
          _storage.get(storageKey(extensionId, '${(args as List)[0]}')),
        ),
        'storage.set' =>
          _storage
              .put(
                storageKey(extensionId, '${(args as List)[0]}'),
                '${args[1]}',
              )
              .then((_) => null),
        'webview.run' => _pages.run(
          extensionId,
          (args as Map)['url'] as String,
          args['script'] as String,
        ),
        _ => Future.error(UnsupportedError('Unknown host call $method')),
      };

  Future<Map<String, Object?>> _fetch(
    String extensionId,
    Map<String, Object?> req,
  ) async {
    final dio = await (_clients[extensionId] ??= _client(extensionId));
    final headers = (req['headers'] as Map?)?.cast<String, Object?>() ?? {};
    Future<Response<String>> send() => dio.request<String>(
      req['url'] as String,
      data: req['body'],
      options: Options(
        method: (req['method'] as String?)?.toUpperCase() ?? 'GET',
        headers: {'User-Agent': userAgent, ...headers},
      ),
    );
    final res = await _retryingConnection(send);
    if (_isChallenge(res)) {
      throw ServerException(Challenge.message(res.realUri.toString()));
    }
    return {
      'status': res.statusCode ?? 0,
      'url': res.realUri.toString(),
      'headers': {
        for (final MapEntry(:key, :value) in res.headers.map.entries)
          key.toLowerCase(): value.join(', '),
      },
      'body': res.data ?? '',
    };
  }

  static const _connectionAttempts = 3;

  /// Runs [send] again when the connection itself fails (TLS handshake,
  /// reset, refused). Some networks intercept connections now and then, e.g.
  /// with a block page certificate; a later attempt often goes through.
  static Future<Response<String>> _retryingConnection(
    Future<Response<String>> Function() send,
  ) async {
    for (var attempt = 1; ; attempt++) {
      try {
        return await send();
      } on DioException catch (e) {
        final connection =
            e.type == DioExceptionType.connectionError ||
            e.error is HandshakeException ||
            e.error is SocketException ||
            // Cronet reports network and certificate errors as net::ERR_*.
            '${e.error}'.contains('net::ERR_');
        if (!connection) rethrow;
        if (attempt >= _connectionAttempts) {
          throw ServerException(
            AppText.connectionFailed(e.requestOptions.uri.host),
          );
        }
        await Future<void>.delayed(Duration(milliseconds: 400 * attempt));
      }
    }
  }

  /// A Cloudflare challenge page instead of the response.
  static bool _isChallenge(Response<String> res) {
    if (res.headers.value('cf-mitigated') == 'challenge') return true;
    final status = res.statusCode;
    if (status != 403 && status != 503) return false;
    final server = res.headers.value('server') ?? '';
    return server.toLowerCase().contains('cloudflare') &&
        RegExp('challenge-platform|Just a moment').hasMatch(res.data ?? '');
  }

  Future<PersistCookieJar> _jar(String extensionId) =>
      _jars[extensionId] ??= () async {
        final dir = await getApplicationSupportDirectory();
        return PersistCookieJar(
          storage: FileStorage(
            '${dir.path}${Platform.pathSeparator}cookies'
            '${Platform.pathSeparator}$extensionId',
          ),
        );
      }();

  /// Copies cookies the WebView got for [uri] (e.g. Cloudflare's
  /// `cf_clearance`) into the extension's jar, so `http.fetch` sends them.
  Future<void> saveCookies(
    String extensionId,
    Uri uri,
    List<Cookie> cookies,
  ) async {
    if (cookies.isEmpty) return;
    await (await _jar(extensionId)).saveFromResponse(uri, cookies);
  }

  /// Forgets the extension's cookies for [uri]'s host.
  Future<void> clearCookies(String extensionId, Uri uri) async =>
      (await _jar(extensionId)).delete(uri, true);

  Future<Dio> _client(String extensionId) async {
    final jar = await _jar(extensionId);
    return Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 30),
          responseType: ResponseType.plain,
          // Scripts read the status themselves.
          validateStatus: (_) => true,
        ),
      )
      // Cronet (Android) / NSURLSession (iOS) instead of dart:io: Cloudflare
      // turns away dart:io's TLS fingerprint even with a valid cf_clearance.
      ..httpClientAdapter = Platform.isAndroid || Platform.isIOS
          ? NativeAdapter(
              createFallbackAdapter: (_, _) => IOHttpClientAdapter(),
            )
          : IOHttpClientAdapter()
      ..interceptors.add(CookieManager(jar));
  }

  /// Clears an extension's cookies and stored values, e.g. on uninstall.
  Future<void> reset(String extensionId) async {
    _clients.remove(extensionId);
    _jars.remove(extensionId);
    _pages.close(extensionId);
    final dir = await getApplicationSupportDirectory();
    final cookies = Directory(
      '${dir.path}${Platform.pathSeparator}cookies'
      '${Platform.pathSeparator}$extensionId',
    );
    if (await cookies.exists()) await cookies.delete(recursive: true);
    await _storage.deleteAll(
      _storage.keys.cast<String>().where((k) => k.startsWith('$extensionId:')),
    );
  }

  /// The Hive key of an extension's stored [key]: `<id>:<key>`, or
  /// `<id>:#<sha256 of key>` when that is too long or not ASCII, which
  /// would corrupt the box ([isValidHiveKey]). Keys stored before stay
  /// where they are; both forms start with `<id>:` for [reset].
  @visibleForTesting
  static String storageKey(String extensionId, String key) {
    final plain = '$extensionId:$key';
    if (isValidHiveKey(plain)) return plain;
    return '$extensionId:#${sha256.convert(utf8.encode(key))}';
  }

  /// Pages at least this long are parsed on another isolate: a site page
  /// of a few hundred KB takes tens of milliseconds to parse, a frame or
  /// more on the main thread. Below it, starting an isolate costs more.
  static const offThreadSelectLength = 32 * 1024;

  /// `html.select`: the elements of [source] matching [selector].
  @visibleForTesting
  static Future<List<Map<String, Object?>>> select(
    String source,
    String selector,
  ) async {
    if (source.length < offThreadSelectLength) return _select(source, selector);
    return Isolate.run(() => _select(source, selector));
  }

  static List<Map<String, Object?>> _select(String source, String selector) => [
    for (final e in html_parser.parse(source).querySelectorAll(selector))
      {
        'text': e.text.trim(),
        'html': e.innerHtml,
        'outerHtml': e.outerHtml,
        'attrs': {for (final a in e.attributes.entries) '${a.key}': a.value},
      },
  ];
}
