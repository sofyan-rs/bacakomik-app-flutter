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

/// Starts the engine of one source; tests give a fake.
typedef SourceLoader = Future<LoadedSource> Function(ExtensionMeta meta);

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
    this._bridge, {
    @ignoreParam this._loader,
  });

  /// Added on first run: the built `dist/` of the private extension source
  /// repo, served from a Cloudflare Worker.
  static const defaultRepo = 'https://bacakomik-ext.kurodev.org/index.json';

  static const _bundledIndex = 'assets/extensions/index.json';
  static const _reposKey = 'repos';
  static const _activeKey = 'active';

  /// Enabled languages of a multi-language extension: `langs:<id>`.
  static String _languagesKey(String extensionId) => 'langs:$extensionId';

  /// Ids become file names and [ComicKey] prefixes.
  static final _validId = RegExp(r'^[a-z0-9][a-z0-9_-]*$');

  final Box<String> _installed;
  final Box<String> _settings;
  final Dio _dio;
  final ExtensionBridge _bridge;
  final SourceLoader? _loader;

  /// Loaded engines by source id.
  final _runtimes = <String, LoadedSource>{};

  /// Engines being loaded, by source id, so callers asking at the same time
  /// share one engine instead of each starting their own.
  final _loading = <String, Future<LoadedSource>>{};

  /// Bumped per extension when its engines are unloaded (update,
  /// uninstall): a load that started before is dropped, not kept.
  final _unloads = <String, int>{};

  /// Newest version of each extension in the repos, from the last
  /// [catalog] fetch.
  var _offered = <String, ExtensionMeta>{};

  /// Newest version of each extension in the repos, from the last
  /// [catalog] fetch; empty before it.
  List<ExtensionMeta> get offered => _offered.values.toList();

  /// Installed extensions the repos have a newer, installable version of.
  int get updateCount => extensions.where((e) {
    final offered = _offered[e.id];
    return offered != null && offered.supported && offered.isNewerThan(e);
  }).length;

  /// Sources to read from, by name: every single-source extension and the
  /// enabled languages of multi-language ones.
  List<ExtensionMeta> get installed => [
    for (final e in extensions)
      if (e.languages.isEmpty)
        e
      else
        for (final language in languagesOf(e.id)) e.forLanguage(language),
  ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

  /// Every source of the installed extensions, enabled or not; names comics
  /// of a language that was turned off.
  List<ExtensionMeta> get knownSources => [
    for (final e in extensions)
      if (e.languages.isEmpty)
        e
      else
        for (final language in e.languages) e.forLanguage(language),
  ];

  /// Installed extensions by name, as installed (one per script).
  List<ExtensionMeta> get extensions {
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

  /// An installed extension, or one language of a multi-language one
  /// (enabled or not, so its comics still open).
  ExtensionMeta? meta(String sourceId) {
    if (_extension(sourceId) case final e?) return e;
    for (final e in extensions) {
      if (e.sourceFor(sourceId) case final source?) return source;
    }
    return null;
  }

  ExtensionMeta? _extension(String extensionId) {
    final raw = _installed.get(extensionId);
    return raw == null
        ? null
        : ExtensionMeta.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  /// Enabled languages of a multi-language extension; English, else its
  /// first language, until the user picks.
  List<String> languagesOf(String extensionId) {
    final all = _extension(extensionId)?.languages ?? const [];
    final raw = _settings.get(_languagesKey(extensionId));
    if (raw != null) {
      final saved = (jsonDecode(raw) as List).cast<String>();
      return [
        for (final l in all)
          if (saved.contains(l)) l,
      ];
    }
    if (all.contains('en')) return const ['en'];
    return all.take(1).toList();
  }

  Future<void> setLanguages(String extensionId, List<String> languages) async {
    await _settings.put(_languagesKey(extensionId), jsonEncode(languages));
    notifyListeners();
  }

  /// Display name of a source, falling back to its id when not installed.
  String nameOf(String sourceId) => meta(sourceId)?.name ?? sourceId;

  /// Name of the source a [ComicKey] belongs to.
  String sourceNameOfKey(String key) => nameOf(ComicKey.sourceOf(key));

  /// The series' page on its site, from the extension's optional `webUrl`;
  /// the source's home page when it has none or it fails.
  Future<String> webUrlOf(String key) async {
    final sourceId = ComicKey.sourceOf(key);
    final home = meta(sourceId)?.baseUrl ?? '';
    try {
      final url = await (await backend(sourceId))
          .call('webUrl', [ComicKey.slugOf(key)]);
      return url is String && url.startsWith('http') ? url : home;
    } catch (_) {
      return home;
    }
  }

  /// Source shown on Home and Explore: the one picked last, else the
  /// default source, else the first installed.
  @override
  String? get activeSource {
    final sources = installed;
    final saved = _settings.get(_activeKey);
    if (saved != null && sources.any((s) => s.id == saved)) return saved;
    if (sources.any((s) => s.id == ComicKey.defaultSource)) {
      return ComicKey.defaultSource;
    }
    return sources.firstOrNull?.id;
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

  /// The loaded engine of [sourceId], loading it on first use. Callers
  /// asking while it loads get the same engine; a failed load is not kept,
  /// so the next call tries again.
  @override
  Future<SourceBackend> backend(String sourceId) => _engine(sourceId);

  Future<LoadedSource> _engine(String sourceId) async {
    if (_runtimes[sourceId] case final runtime?) return runtime;
    if (_loading[sourceId] case final loading?) return loading;
    final loading = _load(sourceId);
    _loading[sourceId] = loading;
    try {
      return await loading;
    } finally {
      if (identical(_loading[sourceId], loading)) _loading.remove(sourceId);
    }
  }

  Future<LoadedSource> _load(String sourceId) async {
    final meta = this.meta(sourceId);
    if (meta == null) {
      throw ServerException('Source "$sourceId" is not installed');
    }
    final extensionId = meta.extensionId;
    final unloads = _unloads[extensionId] ?? 0;
    final runtime = await (_loader ?? _loadScript)(meta);
    if ((_unloads[extensionId] ?? 0) != unloads) {
      // Updated or uninstalled while loading: this engine runs the old
      // script. Drop it and load what is installed now.
      runtime.dispose();
      _loading.remove(sourceId);
      return _engine(sourceId);
    }
    return _runtimes[sourceId] = runtime;
  }

  Future<LoadedSource> _loadScript(ExtensionMeta meta) async {
    final file = await _scriptFile(meta.extensionId);
    if (!await file.exists()) {
      throw ServerException('${meta.name} is not installed');
    }
    return ExtensionRuntime.load(
      meta,
      await file.readAsString(),
      _bridge.handle,
    );
  }

  /// Fetches every repo. A repo that fails is returned as an error entry so
  /// the rest still show. Also refreshes [updateCount].
  Future<List<({String url, ExtensionRepo? repo, String? error})>>
  catalog() async {
    final result = await Future.wait([
      for (final url in repos)
        fetchRepo(url).then<({String url, ExtensionRepo? repo, String? error})>(
          (repo) => (url: url, repo: repo, error: null),
          onError: (Object e) => (url: url, repo: null, error: '$e'),
        ),
    ]);
    final offered = <String, ExtensionMeta>{};
    for (final e in result.expand((r) => r.repo?.extensions ?? const [])) {
      final seen = offered[e.id];
      if (seen == null || e.isNewerThan(seen)) offered[e.id] = e;
    }
    _offered = offered;
    notifyListeners();
    return result;
  }

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

  /// Removes an extension and, for a multi-language one, all its sources.
  Future<void> uninstall(String extensionId) async {
    final sourceIds = [
      for (final s in knownSources)
        if (s.extensionId == extensionId) s.id,
    ];
    _disposeRuntimes(extensionId);
    final file = await _scriptFile(extensionId);
    if (await file.exists()) await file.delete();
    await _installed.delete(extensionId);
    await _settings.delete(_languagesKey(extensionId));
    for (final id in {extensionId, ...sourceIds}) {
      await _bridge.reset(id);
    }
    notifyListeners();
  }

  /// Unloads the engines of an extension's sources; engines still loading
  /// are dropped when they finish.
  void _disposeRuntimes(String extensionId) {
    _unloads.update(extensionId, (n) => n + 1, ifAbsent: () => 1);
    _runtimes.removeWhere((id, runtime) {
      if (runtime.meta.extensionId != extensionId) return false;
      runtime.dispose();
      return true;
    });
  }

  Future<void> _save(ExtensionMeta meta, String script) async {
    final file = await _scriptFile(meta.id);
    await file.parent.create(recursive: true);
    await file.writeAsString(script);
    await _installed.put(meta.id, jsonEncode(meta.toJson()));
    _disposeRuntimes(meta.id);
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
