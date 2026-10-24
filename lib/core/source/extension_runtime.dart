import 'dart:async';
import 'dart:convert';

import 'package:bacakomik_app/core/error/exceptions.dart';
import 'package:bacakomik_app/core/source/extension_meta.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_js/flutter_js.dart';

/// Calls a source's methods. Implemented by [ExtensionRuntime]; tests use
/// fakes.
abstract interface class SourceBackend {
  /// Filter groups and Home filters. Loaded on first use and kept.
  Future<SourceFeatures> features();

  /// Runs `method(...args)` of the extension and returns its JSON result.
  Future<Object?> call(String method, List<Object?> args);
}

/// Host functions an extension can call (`http.fetch`, `html.select`,
/// `storage.get/set`). [args] is the decoded JSON the script passed.
typedef BridgeHandler = Future<Object?> Function(
  String extensionId,
  String method,
  Object? args,
);

/// One extension script loaded in its own JS engine (QuickJS on Android,
/// JavaScriptCore on iOS).
///
/// Host calls are asynchronous on both sides: the script awaits a promise
/// whose resolver is kept by id in [_prelude]; Dart runs the call and settles
/// it with `__bkSettle`. Method calls work the same way in the other
/// direction through `__bkInvoke` and the `bk_result` channel.
class ExtensionRuntime implements SourceBackend {
  ExtensionRuntime._(this.meta, this._js, this._bridge);

  /// Throws [ServerException] when the script does not load or does not call
  /// `defineExtension`.
  static ExtensionRuntime load(
    ExtensionMeta meta,
    String script,
    BridgeHandler bridge,
  ) {
    final js = getJavascriptRuntime(xhr: false);
    final runtime = ExtensionRuntime._(meta, js, bridge);
    try {
      runtime._start(script);
      return runtime;
    } catch (_) {
      runtime.dispose();
      rethrow;
    }
  }

  static const callTimeout = Duration(seconds: 45);

  final ExtensionMeta meta;
  final JavascriptRuntime _js;
  final BridgeHandler _bridge;
  final _calls = <int, Completer<Object?>>{};
  var _nextCall = 0;
  var _disposed = false;

  /// The extension's `home` object, read on load.
  Object? _home;
  var _hasFilters = false;
  Future<SourceFeatures>? _features;

  @override
  Future<SourceFeatures> features() => _features ??=
      () async {
        final groups = _hasFilters ? await call('filters', const []) : null;
        return SourceFeatures.fromJson(home: _home, groups: groups);
      }().catchError((Object e) {
        // A failed load (e.g. offline genre list) is retried next time.
        _features = null;
        throw e;
      });

  void _start(String script) {
    _js.onMessage('bk_bridge', (args) {
      _onBridge(args as Map);
      return null;
    });
    _js.onMessage('bk_result', (args) {
      _onResult(args as Map);
      return null;
    });
    _js.onMessage('bk_log', (args) {
      debugPrint('[${meta.id}] ${(args as List).join(' ')}');
      return null;
    });
    _eval(_prelude, 'prelude.js');
    _eval(script, '${meta.id}.js');
    final described = jsonDecode(_eval('__bkDescribe()', 'describe.js')) as Map;
    _home = described['home'];
    _hasFilters = described['hasFilters'] == true;
  }

  @override
  Future<Object?> call(String method, List<Object?> args) {
    if (_disposed) {
      return Future.error(ServerException('${meta.name} is not loaded'));
    }
    final id = ++_nextCall;
    final completer = _calls[id] = Completer<Object?>();
    _run(
      '__bkInvoke($id, ${jsonEncode(method)}, ${jsonEncode(jsonEncode(args))})',
    );
    return completer.future.timeout(
      callTimeout,
      onTimeout: () {
        _calls.remove(id);
        throw ServerException('${meta.name} did not respond');
      },
    );
  }

  void _onResult(Map message) {
    final completer = _calls.remove(message['id']);
    if (completer == null) return;
    if (message['ok'] == true) {
      completer.complete(message['value']);
    } else {
      completer.completeError(_error('${message['error']}'));
    }
  }

  /// Runs outside the JS call that sent it: the engine is not re-entrant.
  void _onBridge(Map message) {
    final id = message['id'];
    final method = message['method'] as String;
    Future(() => _bridge(meta.id, method, message['args'])).then(
      (value) => _settle(id, true, jsonEncode(value)),
      onError: (Object e) => _settle(id, false, '$e'),
    );
  }

  void _settle(Object? id, bool ok, String payload) {
    if (_disposed) return;
    _run('__bkSettle($id, $ok, ${jsonEncode(payload)})');
  }

  /// Evaluates [code] and drains the promise jobs it queued.
  void _run(String code) {
    final result = _js.evaluate(code);
    _js.executePendingJob();
    if (result.isError) debugPrint('[${meta.id}] ${result.stringResult}');
  }

  String _eval(String code, String file) {
    final result = _js.evaluate(code, sourceUrl: file);
    _js.executePendingJob();
    if (result.isError) {
      throw ServerException('${meta.name}: ${result.stringResult}');
    }
    return result.stringResult;
  }

  /// Scripts signal a missing comic or chapter with a message starting with
  /// `404`, mapped to the status code the app checks.
  static ServerException _error(String message) {
    final clean = message.replaceFirst(RegExp(r'^Error:\s*'), '');
    return ServerException(
      clean,
      statusCode: clean.startsWith('404') ? 404 : null,
    );
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    for (final completer in _calls.values) {
      completer.completeError(ServerException('${meta.name} was unloaded'));
    }
    _calls.clear();
    _js.dispose();
  }

  static const _prelude = r'''
var __bk = { seq: 0, pending: {}, ext: null };

function __bkCall(method, args) {
  return new Promise(function (resolve, reject) {
    var id = ++__bk.seq;
    __bk.pending[id] = { resolve: resolve, reject: reject };
    sendMessage('bk_bridge', JSON.stringify({ id: id, method: method, args: args }));
  });
}

function __bkSettle(id, ok, payload) {
  var p = __bk.pending[id];
  if (!p) return;
  delete __bk.pending[id];
  if (ok) p.resolve(JSON.parse(payload));
  else p.reject(new Error(payload));
}

var http = {
  fetch: function (req) { return __bkCall('http.fetch', req); },
};
var html = {
  select: function (source, selector) { return __bkCall('html.select', [source, selector]); },
};
var storage = {
  get: function (key) { return __bkCall('storage.get', [key]); },
  set: function (key, value) { return __bkCall('storage.set', [key, String(value)]); },
};

function log() {
  var parts = [];
  for (var i = 0; i < arguments.length; i++) {
    var a = arguments[i];
    parts.push(typeof a === 'string' ? a : JSON.stringify(a));
  }
  sendMessage('bk_log', JSON.stringify(parts));
}

function qs(params) {
  var out = [];
  Object.keys(params || {}).forEach(function (key) {
    var values = Array.isArray(params[key]) ? params[key] : [params[key]];
    values.forEach(function (v) {
      if (v === null || v === undefined || v === '') return;
      out.push(encodeURIComponent(key) + '=' + encodeURIComponent(String(v)));
    });
  });
  return out.join('&');
}

function defineExtension(ext) {
  if (__bk.ext) throw new Error('defineExtension called twice');
  __bk.ext = ext;
}

function __bkDescribe() {
  if (!__bk.ext) throw new Error('Extension did not call defineExtension');
  return JSON.stringify({
    home: __bk.ext.home || {},
    hasFilters: typeof __bk.ext.filters === 'function',
  });
}

function __bkInvoke(id, method, argsJson) {
  Promise.resolve()
    .then(function () {
      var fn = __bk.ext && __bk.ext[method];
      if (typeof fn !== 'function') throw new Error('Unknown method ' + method);
      return fn.apply(__bk.ext, JSON.parse(argsJson));
    })
    .then(
      function (value) {
        sendMessage('bk_result', JSON.stringify({ id: id, ok: true, value: value === undefined ? null : value }));
      },
      function (e) {
        sendMessage('bk_result', JSON.stringify({ id: id, ok: false, error: String((e && e.message) || e) }));
      }
    );
}
''';
}
