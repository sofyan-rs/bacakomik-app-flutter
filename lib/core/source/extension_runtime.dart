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

/// A loaded source engine that can be unloaded.
abstract interface class LoadedSource implements SourceBackend {
  ExtensionMeta get meta;

  void dispose();
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
class ExtensionRuntime implements LoadedSource {
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

  /// How long a call may go without progress: neither a host function
  /// running nor one finishing. A long run of host calls (a chapter list
  /// read page by page in a WebView) is not cut off.
  static const callTimeout = Duration(seconds: 45);

  @override
  final ExtensionMeta meta;
  final JavascriptRuntime _js;
  final BridgeHandler _bridge;
  final _calls = <int, Completer<Object?>>{};
  var _nextCall = 0;
  var _disposed = false;

  /// Host functions running, and when the last one started or finished.
  var _hostCalls = 0;
  var _lastProgress = DateTime.now();

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
    // The source this engine runs as; a multi-language script reads `lang`.
    _eval(
      'var source = ${jsonEncode({'id': meta.id, 'lang': meta.lang})};',
      'source.js',
    );
    _eval(script, '${meta.extensionId}.js');
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
    _lastProgress = DateTime.now();
    _run('__bkInvoke($id, ${jsonEncode(method)}, ${jsLiteral(args)})');
    final idle = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_hostCalls > 0 ||
          DateTime.now().difference(_lastProgress) < callTimeout) {
        return;
      }
      timer.cancel();
      if (_calls.remove(id) case final pending?) {
        pending.completeError(ServerException('${meta.name} did not respond'));
      }
    });
    return completer.future.whenComplete(idle.cancel);
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
    _hostCalls++;
    _lastProgress = DateTime.now();
    Future(() => _bridge(meta.id, method, message['args']))
        .whenComplete(() {
          _hostCalls--;
          _lastProgress = DateTime.now();
        })
        .then(
          (value) => _settle(id, true, value),
          onError: (Object e) => _settle(id, false, '$e'),
        );
  }

  /// Resolves the script's promise with [value], or rejects it with the
  /// message [value].
  void _settle(Object? id, bool ok, Object? value) {
    if (_disposed) return;
    _run('__bkSettle($id, $ok, ${jsLiteral(value)})');
  }

  /// [value] as a JavaScript expression evaluating to what
  /// `JSON.parse(jsonEncode(value))` gives, encoded once: a response body
  /// goes into the engine at its own size, not escaped twice and parsed
  /// twice.
  ///
  /// JSON is a JavaScript literal, except that a `"__proto__"` key in an
  /// object literal sets the prototype instead of a property; such values
  /// (e.g. from a site's own JSON) go through `JSON.parse` as before. U+2028
  /// and U+2029, legal in JSON strings, are escaped for engines older than
  /// ES2019.
  @visibleForTesting
  static String jsLiteral(Object? value) {
    final json = jsonEncode(value);
    if (json.contains('"__proto__"')) return 'JSON.parse(${jsonEncode(json)})';
    if (!json.contains(' ') && !json.contains(' ')) return json;
    return json.replaceAll(' ', r' ').replaceAll(' ', r' ');
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

  @override
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

// [value] is the result itself, or the error message.
function __bkSettle(id, ok, value) {
  var p = __bk.pending[id];
  if (!p) return;
  delete __bk.pending[id];
  if (ok) p.resolve(value);
  else p.reject(new Error(value));
}

var http = {
  fetch: function (req) { return __bkCall('http.fetch', req); },
};
var html = {
  select: function (source, selector) { return __bkCall('html.select', [source, selector]); },
};
var webview = {
  // Runs [script] (an async function, or the body of one) inside [url] in a
  // hidden WebView; resolves with its JSON-able result. A function is sent
  // as source, so it cannot use variables of the extension; pass them in
  // [args].
  run: function (url, script) {
    var args = Array.prototype.slice.call(arguments, 2);
    var body = typeof script === 'function'
      ? 'return await (' + String(script) + ').apply(null, ' + JSON.stringify(args) + ');'
      : String(script);
    return __bkCall('webview.run', { url: url, script: body });
  },
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

function __bkInvoke(id, method, args) {
  Promise.resolve()
    .then(function () {
      var fn = __bk.ext && __bk.ext[method];
      if (typeof fn !== 'function') throw new Error('Unknown method ' + method);
      return fn.apply(__bk.ext, args);
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
