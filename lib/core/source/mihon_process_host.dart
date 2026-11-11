import 'dart:async';
import 'dart:convert';
import 'dart:ffi' show Abi;
import 'dart:io';
import 'dart:isolate';

import 'package:archive/archive_io.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:yoru/core/constants/variables.dart';
import 'package:yoru/core/error/exceptions.dart';
import 'package:yoru/core/source/extension_bridge.dart';
import 'package:yoru/core/source/mihon_host.dart';

/// [MihonHost] on Windows, macOS and Linux: the Kotlin host from
/// `desktop/mihon-host` run as a helper process on a Java runtime the app
/// downloads on first use ([MihonRuntime]). It speaks JSON lines over
/// stdin/stdout (docs/ARCHITECTURE.md §8.9):
///
/// - host, once started: `{"ready":true,"version":"2","libs":[…]}`
/// - app: `{"id":1,"method":"handle","params":{"method":"…","args":{…}}}`,
///   `{"id":2,"method":"image","params":{"url":"mihon://…"}}`
/// - host: `{"id":1,"result":…}` or `{"id":1,"error":{"message","status",
///   "verifyUrl","verifyAgent"}}`, in any order
/// - host asks: `{"ask":7,"method":"solveBrowserCheck","params":{…}}`, the
///   app answers `{"answer":7,"result":…}`
///
/// The process starts on the first call and stays for the app's run.
class ProcessMihonHost implements MihonHost {
  ProcessMihonHost._();

  /// What the host is downloading now, for the app to show
  /// ([MihonDownloadPill]); null when nothing is.
  static final downloads = ValueNotifier<MihonDownload?>(null);

  static final instance = ProcessMihonHost._();

  /// Answers a browser check the host asks about: the site's cookies once
  /// passed, or null. Null (the default) lets the call fail with the check,
  /// which the app then offers to pass in its WebView ("Verify in
  /// WebView"); [setCookies] hands the host what that WebView got.
  static Future<List<String>?> Function(
    Uri url,
    String userAgent,
    Map<String, String> headers,
  )?
  solveBrowserCheck;

  Future<_HostProcess>? _process;

  @override
  Future<bool> get available async => MihonRuntime.platform != null;

  @override
  Future<void> prepare({void Function(double progress)? onProgress}) async {
    await _start(onProgress: onProgress);
  }

  Future<_HostProcess> _start({void Function(double progress)? onProgress}) =>
      _process ??=
          () async {
            final runtime = await MihonRuntime.instance.ensure(
              onProgress: onProgress,
            );
            final support = await getApplicationSupportDirectory();
            final info = await PackageInfo.fromPlatform();
            final process = await _HostProcess.start(
              runtime,
              root: '${support.path}${Platform.pathSeparator}mihon',
              userAgent: ExtensionBridge.userAgent,
              appVersion: info.version,
            );
            unawaited(
              process.exited.then((_) {
                // Started again by the next call.
                if (identical(_process, process)) _process = null;
              }),
            );
            return process;
          }().catchError((Object e) {
            _process = null;
            throw e;
          });

  @override
  Future<Object?> handle(String method, Map<String, Object?> args) async {
    final process = await _start();
    return process.request('handle', {'method': method, 'args': args});
  }

  @override
  Future<({Uint8List bytes, String? type})> image(String url) async {
    final process = await _start();
    final result = await process.request('image', {'url': url});
    final map = result is Map ? result : const {};
    final bytes = base64Decode(map['bytes'] as String? ?? '');
    if (bytes.isEmpty) throw ServerException('Empty image: $url');
    return (bytes: bytes, type: map['type'] as String?);
  }

  /// No background downloader on the desktops: pages are saved in the app.
  @override
  Future<String?> httpUrl(String url) async => null;

  @override
  Future<void> setCookies(Uri url, List<String> cookies) async {
    if (cookies.isEmpty || _process == null) return;
    await handle('setCookies', {'url': url.toString(), 'cookies': cookies});
  }
}

/// One running host: requests by id, the host's asks, its exit.
class _HostProcess {
  _HostProcess._(this._process);

  final Process _process;
  final _pending = <int, Completer<Object?>>{};
  var _nextId = 0;
  final _ready = Completer<void>();

  Future<int> get exited => _process.exitCode;

  static const _mainClass = 'org.kurodev.yoru.mihon.desktop.MainKt';

  static Future<_HostProcess> start(
    Directory runtime, {
    required String root,
    required String userAgent,
    required String appVersion,
  }) async {
    final sep = Platform.pathSeparator;
    final java =
        '${runtime.path}${sep}bin${sep}java'
        '${Platform.isWindows ? '.exe' : ''}';
    final process = await Process.start(java, [
      '-Xss2m',
      '-XX:+UseSerialGC',
      '-XX:TieredStopAtLevel=1',
      '-Dfile.encoding=UTF-8',
      '-cp',
      '${runtime.path}${sep}lib${sep}host$sep*',
      _mainClass,
      '--root',
      root,
      '--user-agent',
      userAgent,
      '--app-version',
      appVersion,
    ]);
    final host = _HostProcess._(process);
    process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(host._onLine, onDone: host._onDone);
    // What extensions print, for debugging.
    process.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) => debugPrint('mihon-host: $line'));
    unawaited(process.exitCode.then((_) => host._onDone()));
    await host._ready.future.timeout(
      const Duration(seconds: 60),
      onTimeout: () {
        process.kill();
        throw const ServerException('The Mihon host did not start');
      },
    );
    return host;
  }

  Future<Object?> request(String method, Map<String, Object?> params) {
    final id = ++_nextId;
    final done = _pending[id] = Completer<Object?>();
    _send({'id': id, 'method': method, 'params': params});
    return done.future;
  }

  void _send(Map<String, Object?> message) {
    _process.stdin.writeln(jsonEncode(message));
  }

  void _onLine(String line) {
    if (line.trim().isEmpty) return;
    final Object? message;
    try {
      message = jsonDecode(line);
    } on FormatException {
      debugPrint('mihon-host (not JSON): $line');
      return;
    }
    if (message is! Map) return;
    if (message['ready'] == true) {
      if (!_ready.isCompleted) _ready.complete();
      return;
    }
    // `{"event":"progress","what":"chromium","progress":0.4}`: the browser
    // an extension needs, downloaded the first time one opens a page.
    if (message['event'] == 'progress') {
      final progress = (message['progress'] as num?)?.toDouble() ?? 0;
      final what = message['what'] == 'chromium'
          ? MihonDownloadKind.browser
          : MihonDownloadKind.runtime;
      ProcessMihonHost.downloads.value = progress >= 1
          ? null
          : MihonDownload(what, progress);
      return;
    }
    if (message['ask'] case final int ask) {
      unawaited(_answer(ask, message['method'], message['params']));
      return;
    }
    final done = _pending.remove(message['id']);
    if (done == null) return;
    if (message['error'] case final Map error) {
      done.completeError(failure(error));
    } else {
      done.complete(message['result']);
    }
  }

  Future<void> _answer(int ask, Object? method, Object? params) async {
    Object? result;
    try {
      if (method == 'solveBrowserCheck' && params is Map) {
        final solve = ProcessMihonHost.solveBrowserCheck;
        final cookies = solve == null
            ? null
            : await solve(
                Uri.parse(params['url'] as String),
                params['userAgent'] as String? ?? ExtensionBridge.userAgent,
                {
                  for (final MapEntry(:key, :value)
                      in ((params['headers'] as Map?) ?? const {}).entries)
                    '$key': '$value',
                },
              );
        result = cookies == null ? null : {'cookies': cookies};
      }
    } catch (e) {
      debugPrint('mihon-host ask $method failed: $e');
    }
    _send({'answer': ask, 'result': result});
  }

  void _onDone() {
    ProcessMihonHost.downloads.value = null;
    const gone = ServerException('The Mihon host stopped');
    if (!_ready.isCompleted) _ready.completeError(gone);
    for (final done in _pending.values) {
      done.completeError(gone);
    }
    _pending.clear();
  }

  /// A host error as the app's errors, as [ChannelMihonHost.failure] words
  /// them: a browser check becomes [Challenge.message].
  @visibleForTesting
  static ServerException failure(Map error) {
    final status = (error['status'] as num?)?.toInt();
    final message = error['message'] as String? ?? 'Mihon extension failed';
    if (error['verifyUrl'] case final String verifyUrl) {
      return ServerException(Challenge.message(verifyUrl), statusCode: status);
    }
    return ServerException(
      status == 404 && !message.startsWith('404') ? '404 $message' : message,
      statusCode: status,
    );
  }
}

/// The Java runtime and host jars the desktop [ProcessMihonHost] runs on,
/// downloaded once from the app's GitHub releases (about 100 MB) so the app
/// stays small for everyone who does not use Mihon extensions.
///
/// For development, `YORU_MIHON_RUNTIME` names a runtime folder to use
/// instead (`desktop/mihon-host/host/build/runtime/...`).
class MihonRuntime {
  MihonRuntime._();

  static final instance = MihonRuntime._();

  /// Bumped with every host change the app needs; one folder per version.
  static const version = '2';

  /// SHA-256 of each platform's runtime zip, from the release that built
  /// it (its SHA256SUMS). A platform without one cannot download the
  /// runtime.
  static const _sha256 = <String, String>{
    'windows-x64':
        'ecb2673bdd399ae8e596ac6470c1d4e1515d02844eea53bb74358af2b14ebfb9',
    'linux-x64':
        '6294857a5797daa90091d196d7d17c5d50b67e191177cdc446c6c3c62f71f9d5',
    'linux-arm64':
        'ebd985c3a827effca35882808571626e6d642d04844b2569f8da985bc2b85fdd',
    'macos-x64':
        '81050124d7c2bedec235e73a847fcdd195c420eeecddb9f94ae1d3ea8a3236c7',
    'macos-arm64':
        '69372616553d9363d3fc6cfd80b444bafdc042dbd49f2fc8bdf53bf9ffd4c9b4',
  };

  /// `windows-x64`, `macos-arm64`, …; null where there is no runtime.
  static String? get platform {
    if (kIsWeb) return null;
    final arch = _arch;
    if (Platform.isWindows) return 'windows-$arch';
    if (Platform.isMacOS) return 'macos-$arch';
    if (Platform.isLinux) return 'linux-$arch';
    return null;
  }

  static String get _arch {
    final abi = Abi.current();
    return abi == Abi.macosArm64 || abi == Abi.linuxArm64 ? 'arm64' : 'x64';
  }

  static String get _zipName =>
      'yoru-mihon-runtime-$version-${platform ?? 'unknown'}.zip';

  static String get _url =>
      'https://github.com/${AppVariables.githubRepo}/releases/download/'
      'mihon-runtime-v$version/$_zipName';

  Future<Directory>? _ready;

  /// The runtime folder, downloading and unpacking it first when needed.
  Future<Directory> ensure({void Function(double progress)? onProgress}) =>
      _ready ??= _ensure(onProgress).catchError((Object e) {
        _ready = null;
        throw e;
      });

  Future<Directory> _ensure(void Function(double)? onProgress) async {
    final override = Platform.environment['YORU_MIHON_RUNTIME'];
    if (override != null && override.isNotEmpty) return Directory(override);
    if (platform == null) {
      throw const ServerException('Mihon extensions do not run here');
    }
    final support = await getApplicationSupportDirectory();
    final sep = Platform.pathSeparator;
    final dir = Directory('${support.path}${sep}mihon-runtime$sep$version');
    final marker = File('${dir.path}$sep.complete');
    if (await marker.exists()) {
      unawaited(_deleteOtherVersions(dir));
      return dir;
    }

    final expected = _sha256[platform];
    if (expected == null) {
      throw const ServerException(
        'The Mihon runtime for this system is not available yet',
      );
    }
    final part = File('${support.path}$sep$_zipName.part');
    // The unpacker goes by the name's extension: the checked file is
    // renamed to `.zip` first.
    final zip = File('${support.path}$sep$_zipName');
    final unpacked = Directory('${dir.parent.path}${sep}yoru-mihon-runtime');
    try {
      await Dio().download(
        _url,
        part.path,
        onReceiveProgress: (got, total) {
          if (total <= 0) return;
          onProgress?.call(got / total);
          ProcessMihonHost.downloads.value = MihonDownload(
            MihonDownloadKind.runtime,
            got / total,
          );
        },
      );
      final digest = await sha256.bind(part.openRead()).first;
      if ('$digest' != expected) {
        throw const ServerException('The Mihon runtime download is damaged');
      }
      await part.rename(zip.path);
      for (final old in [dir, unpacked]) {
        if (await old.exists()) await old.delete(recursive: true);
      }
      // About 100 MB to inflate: off the UI isolate.
      final from = zip.path;
      final to = dir.parent.path;
      await Isolate.run(() => extractFileToDisk(from, to));
      // The zip holds one folder, `yoru-mihon-runtime`: it becomes [dir].
      if (!await unpacked.exists()) {
        throw const ServerException('The Mihon runtime download is damaged');
      }
      await unpacked.rename(dir.path);
      if (!Platform.isWindows) {
        await Process.run('chmod', ['-R', 'u+x', '${dir.path}${sep}bin']);
      }
      await marker.writeAsString(version);
      unawaited(_deleteOtherVersions(dir));
      return dir;
    } finally {
      ProcessMihonHost.downloads.value = null;
      for (final file in [part, zip]) {
        if (await file.exists()) await file.delete();
      }
    }
  }
}

/// Runtimes of other versions beside [current] (about 110 MB each), left
/// by an update of the app. Best effort: a folder in use stays.
Future<void> _deleteOtherVersions(Directory current) async {
  try {
    await for (final entry in current.parent.list()) {
      if (entry is Directory && entry.path != current.path) {
        await entry.delete(recursive: true);
      }
    }
  } catch (e) {
    debugPrint('Old Mihon runtimes not deleted: $e');
  }
}

/// What a desktop Mihon download is for.
enum MihonDownloadKind {
  /// The Java runtime and host, before the first extension installs.
  runtime,

  /// Chromium, the first time an extension opens a web page itself.
  browser,
}

/// A download of [ProcessMihonHost], [progress] from 0 to 1.
@immutable
class MihonDownload {
  const MihonDownload(this.kind, this.progress);

  final MihonDownloadKind kind;
  final double progress;
}
