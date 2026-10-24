import 'dart:convert';
import 'dart:io';

import 'package:bacakomik_app/core/di/register_module.dart';
import 'package:bacakomik_app/core/error/exceptions.dart';
import 'package:bacakomik_app/core/source/comic_key.dart';
import 'package:bacakomik_app/core/source/extension_bridge.dart';
import 'package:bacakomik_app/core/source/extension_meta.dart';
import 'package:bacakomik_app/core/source/extension_runtime.dart';
import 'package:bacakomik_app/core/storage/hive_boxes.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hive_ce/hive.dart';
import 'package:injectable/injectable.dart';
import 'package:path_provider/path_provider.dart';

/// Error shown by Home and Explore when no source is installed.
const noSourceMessage = 'No source installed. Add one in Extensions.';

/// A repo's `index.json`.
class ExtensionRepo {
  const ExtensionRepo({
    required this.url,
    required this.name,
    required this.extensions,
  });

  final String url;
  final String name;
  final List<ExtensionMeta> extensions;
}

/// Gives the [SourceBackend] of a source id. Implemented by
/// [ExtensionManager]; tests use fakes.
abstract interface class SourceRegistry {
  /// Source of Home and Explore; null when nothing is installed.
  String? get activeSource;

  /// Throws [ServerException] when the source is not installed or its
  /// script fails to load.
  Future<SourceBackend> backend(String sourceId);
}

/// Installed extensions, the repos they come from, and their loaded
/// runtimes.
///
/// Scripts live in `<app support>/extensions/<id>.js`; their metadata in the
/// [HiveBoxes.extensions] box. Extensions shipped in `assets/extensions/`
/// are installed on first run and whenever the app bundles a newer version,
/// so the app works before any repo is reachable.
@lazySingleton
class ExtensionManager extends ChangeNotifier implements SourceRegistry {
  ExtensionManager(
    @Named(HiveBoxes.extensions) this._installed,
    @Named(HiveBoxes.sourceSettings) this._settings,
    @Named(filesDio) this._dio,
    this._bridge,
  );

  /// Added on first run; the public repo holds the built `dist/` of the
  /// private extension source repo.
  static const defaultRepo =
      'https://raw.githubusercontent.com/sofyan-rs/bacakomik-ext/main/index.json';

  static const _bundledIndex = 'assets/extensions/index.json';
  static const _reposKey = 'repos';
  static const _activeKey = 'active';

  /// Ids become file names and [ComicKey] prefixes.
  static final _validId = RegExp(r'^[a-z0-9][a-z0-9_-]*$');

  final Box<String> _installed;
  final Box<String> _settings;
  final Dio _dio;
  final ExtensionBridge _bridge;
  final _runtimes = <String, ExtensionRuntime>{};

  /// Installed extensions by name.
  List<ExtensionMeta> get installed {
    final list = <ExtensionMeta>[];
    for (final raw in _installed.values) {
      try {
        list.add(
          ExtensionMeta.fromJson(jsonDecode(raw) as Map<String, dynamic>),
        );
      } catch (e) {
        debugPrint('Skipping unreadable extension: $e');
      }
    }
    return list
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  ExtensionMeta? meta(String sourceId) {
    final raw = _installed.get(sourceId);
    return raw == null
        ? null
        : ExtensionMeta.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  /// Display name of a source, falling back to its id when not installed.
  String nameOf(String sourceId) => meta(sourceId)?.name ?? sourceId;

  /// Name of the source a [ComicKey] belongs to.
  String sourceNameOfKey(String key) => nameOf(ComicKey.sourceOf(key));

  /// Source shown on Home and Explore: the one picked last, else the
  /// default source, else the first installed.
  @override
  String? get activeSource {
    final saved = _settings.get(_activeKey);
    if (saved != null && _installed.containsKey(saved)) return saved;
    if (_installed.containsKey(ComicKey.defaultSource)) {
      return ComicKey.defaultSource;
    }
    return installed.firstOrNull?.id;
  }

  Future<void> setActiveSource(String sourceId) async {
    await _settings.put(_activeKey, sourceId);
    notifyListeners();
  }

  List<String> get repos {
    final raw = _settings.get(_reposKey);
    if (raw == null) return const [defaultRepo];
    return (jsonDecode(raw) as List).cast<String>();
  }

  /// Installs or upgrades the bundled extensions. Called once on start.
  Future<void> installBundled() async {
    final Map<String, dynamic> index;
    try {
      index = jsonDecode(await rootBundle.loadString(_bundledIndex));
    } catch (e) {
      debugPrint('No bundled extensions: $e');
      return;
    }
    for (final json
        in (index['extensions'] as List).cast<Map<String, dynamic>>()) {
      final bundled = ExtensionMeta.fromJson(json);
      final current = meta(bundled.id);
      if (current != null && !bundled.isNewerThan(current)) continue;
      try {
        final script = await rootBundle.loadString(
          'assets/extensions/${bundled.file}',
        );
        await _save(bundled, script);
      } catch (e) {
        debugPrint('Bundled extension ${bundled.id} failed: $e');
      }
    }
    notifyListeners();
  }

  @override
  Future<SourceBackend> backend(String sourceId) async {
    if (_runtimes[sourceId] case final runtime?) return runtime;
    final meta = this.meta(sourceId);
    if (meta == null) {
      throw ServerException('Source "$sourceId" is not installed');
    }
    final file = await _scriptFile(sourceId);
    if (!await file.exists()) {
      throw ServerException('${meta.name} is not installed');
    }
    final runtime = ExtensionRuntime.load(
      meta,
      await file.readAsString(),
      _bridge.handle,
    );
    return _runtimes[sourceId] = runtime;
  }

  /// Fetches every repo. A repo that fails is returned as an error entry so
  /// the rest still show.
  Future<List<({String url, ExtensionRepo? repo, String? error})>> catalog() =>
      Future.wait([
        for (final url in repos)
          fetchRepo(url).then(
            (repo) => (url: url, repo: repo, error: null),
            onError: (Object e) => (url: url, repo: null, error: '$e'),
          ),
      ]);

  Future<ExtensionRepo> fetchRepo(String url) async {
    final res = await _dio.get<String>(
      url,
      options: Options(responseType: ResponseType.plain),
    );
    final json = jsonDecode(res.data ?? '');
    if (json is! Map || json['extensions'] is! List) {
      throw const FormatException('Not an extension repo index');
    }
    return ExtensionRepo(
      url: url,
      name: json['name'] as String? ?? Uri.parse(url).host,
      extensions: [
        for (final e
            in (json['extensions'] as List).cast<Map<String, dynamic>>())
          ExtensionMeta.fromJson(e, repoUrl: url),
      ],
    );
  }

  /// Validates [url] as a repo and adds it. Returns the repo.
  Future<ExtensionRepo> addRepo(String url) async {
    final clean = url.trim();
    final repo = await fetchRepo(clean);
    if (!repos.contains(clean)) await _saveRepos([...repos, clean]);
    notifyListeners();
    return repo;
  }

  Future<void> removeRepo(String url) async {
    await _saveRepos(repos.where((r) => r != url).toList());
    notifyListeners();
  }

  /// Downloads, verifies and loads [meta] from its repo, replacing any
  /// installed version.
  Future<void> install(ExtensionMeta meta) async {
    if (!meta.supported) {
      throw const ServerException('This extension needs a newer app version');
    }
    final repoUrl = meta.repoUrl;
    if (repoUrl == null) throw const ServerException('Unknown extension repo');
    final res = await _dio.get<List<int>>(
      Uri.parse(repoUrl).resolve(meta.file).toString(),
      options: Options(responseType: ResponseType.bytes),
    );
    final bytes = res.data ?? const <int>[];
    if (sha256.convert(bytes).toString() != meta.sha256.toLowerCase()) {
      throw const ServerException('Extension file does not match its checksum');
    }
    final script = utf8.decode(bytes);
    // A script that does not load is not installed.
    ExtensionRuntime.load(meta, script, _bridge.handle).dispose();
    await _save(meta, script);
    notifyListeners();
  }

  Future<void> uninstall(String sourceId) async {
    _runtimes.remove(sourceId)?.dispose();
    final file = await _scriptFile(sourceId);
    if (await file.exists()) await file.delete();
    await _installed.delete(sourceId);
    await _bridge.reset(sourceId);
    notifyListeners();
  }

  Future<void> _save(ExtensionMeta meta, String script) async {
    final file = await _scriptFile(meta.id);
    await file.parent.create(recursive: true);
    await file.writeAsString(script);
    await _installed.put(meta.id, jsonEncode(meta.toJson()));
    _runtimes.remove(meta.id)?.dispose();
  }

  Future<void> _saveRepos(List<String> list) =>
      _settings.put(_reposKey, jsonEncode(list));

  Future<File> _scriptFile(String id) async {
    if (!_validId.hasMatch(id)) {
      throw ServerException('Invalid extension id "$id"');
    }
    final dir = await getApplicationSupportDirectory();
    return File(
      '${dir.path}${Platform.pathSeparator}extensions${Platform.pathSeparator}$id.js',
    );
  }
}
