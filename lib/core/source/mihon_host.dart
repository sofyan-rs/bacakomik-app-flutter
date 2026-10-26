import 'dart:convert';
import 'dart:io';

import 'package:bacakomik_app/core/error/exceptions.dart';
import 'package:bacakomik_app/core/source/extension_bridge.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// The Kotlin side that runs Mihon extension APKs (Android 9+ only; see
/// docs/ARCHITECTURE.md §8.9). Behind an interface so tests, and one day a
/// desktop host, can stand in.
abstract interface class MihonHost {
  /// Whether this device can run Mihon extensions.
  Future<bool> get available;

  /// Calls `MihonHost.handle` in Kotlin: [method] with [args], JSON result.
  /// Throws [ServerException] (a browser check as [Challenge.message]).
  Future<Object?> handle(String method, Map<String, Object?> args);

  /// The bytes and content type of a `mihon://` image.
  Future<({Uint8List bytes, String? type})> image(String url);

  /// [url] (a `mihon://` image) as an `http://127.0.0.1` URL the background
  /// downloader can fetch while the app is closed (`MihonProxy.kt`); null
  /// where there is none.
  Future<String?> httpUrl(String url);
}

/// [MihonHost] over the `bacakomik/mihon` channel (`MihonChannel.kt`).
class ChannelMihonHost implements MihonHost {
  ChannelMihonHost._();

  static final instance = ChannelMihonHost._();

  static const _channel = MethodChannel('bacakomik/mihon');

  Future<bool>? _available;
  Future<void>? _started;

  @override
  Future<bool> get available => _available ??= () async {
    if (kIsWeb || !Platform.isAndroid) return false;
    try {
      return await _channel.invokeMethod<bool>('supported') ?? false;
    } on MissingPluginException {
      return false;
    }
  }();

  /// Once per run, before the first call: the User-Agent the app's
  /// WebViews use, so a clearance passed there works for extensions.
  Future<void> _start() => _started ??=
      () async {
        final info = await PackageInfo.fromPlatform();
        await _channel.invokeMethod<void>('start', {
          'userAgent': ExtensionBridge.userAgent,
          'appVersion': info.version,
        });
      }().catchError((Object e) {
        _started = null;
        throw e;
      });

  @override
  Future<Object?> handle(String method, Map<String, Object?> args) =>
      _guard(() async {
        await _start();
        final result = await _channel.invokeMethod<String>('handle', {
          'method': method,
          'args': jsonEncode(args),
        });
        return result == null ? null : jsonDecode(result);
      });

  @override
  Future<({Uint8List bytes, String? type})> image(String url) =>
      _guard(() async {
        await _start();
        final result = await _channel.invokeMapMethod<String, Object?>(
          'image',
          {'url': url},
        );
        final bytes = result?['bytes'] as Uint8List?;
        // Not cached (or saved as a downloaded page) as if it were one.
        if (bytes == null || bytes.isEmpty) {
          throw ServerException('Empty image: $url');
        }
        return (bytes: bytes, type: result?['type'] as String?);
      });

  Future<String?>? _proxyBase;

  @override
  Future<String?> httpUrl(String url) async {
    final base = await (_proxyBase ??= () async {
      if (!await available) return null;
      try {
        return await _channel.invokeMethod<String>('proxyBase');
      } catch (_) {
        return null;
      }
    }());
    return base == null
        ? null
        : '$base/image?u=${Uri.encodeQueryComponent(url)}';
  }

  static Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on PlatformException catch (e) {
      throw failure(e);
    } on MissingPluginException {
      throw const ServerException('Mihon extensions run on Android only');
    }
  }

  /// A Kotlin failure as the app's errors: a browser check becomes
  /// [Challenge.message], status 404 a 404 [ServerException].
  @visibleForTesting
  static ServerException failure(PlatformException e) {
    final details = e.details;
    final verifyUrl = details is Map ? details['verifyUrl'] as String? : null;
    final status = int.tryParse(e.code);
    final message = e.message ?? 'Mihon extension failed';
    if (verifyUrl != null) {
      return ServerException(Challenge.message(verifyUrl), statusCode: status);
    }
    return ServerException(
      status == 404 && !message.startsWith('404') ? '404 $message' : message,
      statusCode: status,
    );
  }
}
