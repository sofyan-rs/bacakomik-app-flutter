import 'dart:convert';

import 'package:bacakomik_app/core/source/extension_meta.dart';
import 'package:bacakomik_app/core/source/mihon_store.dart';
import 'package:dio/dio.dart';

/// Mihon extension repos (e.g. Keiyoushi): a base URL with `repo.json`
/// (`{meta: {name, signingKeyFingerprint}}`), `index.min.json` (one entry
/// per extension), `apk/<file>` and `icon/<pkg>.png`. Stored by their
/// `index.min.json` URL.
abstract final class MihonRepo {
  static const indexFile = 'index.min.json';

  static bool isRepoUrl(String url) =>
      Uri.tryParse(url.trim())?.path.endsWith(indexFile) ?? false;

  /// The `index.min.json` URL for what a user typed: that URL, a
  /// `repo.json` next to it, or the repo's base. Null when [url] does not
  /// look like a Mihon repo.
  static String? normalize(String url) {
    final uri = Uri.tryParse(url.trim());
    if (uri == null || !uri.hasScheme) return null;
    final path = uri.path;
    if (path.endsWith(indexFile)) return uri.toString();
    if (path.endsWith('repo.json')) return uri.resolve(indexFile).toString();
    if (path.endsWith('.json')) return null;
    final base = path.endsWith('/') ? uri : uri.replace(path: '$path/');
    return base.resolve(indexFile).toString();
  }

  /// The repo's name and its extensions: from its `index_v2` store
  /// (Mihon 0.20.1+, see [MihonStore]) when `repo.json` names one, else
  /// from `index.min.json`. Refuses a repo without a signing key: the key is
  /// what keeps a swapped APK out.
  static Future<({String name, List<ExtensionMeta> extensions})> fetch(
    Dio dio,
    String indexUrl,
  ) async {
    final index = Uri.parse(indexUrl);
    final res = await dio.get<String>(
      index.resolve('repo.json').toString(),
      options: Options(responseType: ResponseType.plain),
    );
    final repo = jsonDecode(res.data ?? '');
    final meta = repo is Map ? repo['meta'] : null;
    final name = meta is Map ? meta['name'] as String? : null;
    var signer = meta is Map ? meta['signingKeyFingerprint'] as String? : null;
    final v2 = repo is Map ? repo['index_v2'] : null;
    if (v2 is String && v2.isNotEmpty) {
      final storeUrl = index.resolve(v2);
      final store = MihonStore.parse(await _bytes(dio, storeUrl));
      signer ??= store.signingKey;
      var extensions = store.extensions;
      if (extensions == null && store.listUrl != null) {
        extensions = MihonStore.parseList(
          await _bytes(dio, storeUrl.resolve(store.listUrl!)),
        );
      }
      final key = _checkSigner(signer);
      return (
        name: name ?? index.host,
        extensions: [
          for (final e in extensions ?? const <StoreExtension>[])
            ?fromStore(e, repoUrl: indexUrl, signer: key),
        ],
      );
    }
    final key = _checkSigner(signer);
    final list = await dio.get<String>(
      indexUrl,
      options: Options(responseType: ResponseType.plain),
    );
    final entries = jsonDecode(list.data ?? '');
    if (entries is! List) throw const FormatException('Not a Mihon repo index');
    return (
      name: name ?? index.host,
      extensions: [
        for (final e in entries)
          if (e is Map)
            ?entry(e.cast<String, dynamic>(), repoUrl: indexUrl, signer: key),
      ],
    );
  }

  static String _checkSigner(String? signer) {
    if (signer == null || signer.isEmpty) {
      throw const FormatException('Mihon repo without a signing key');
    }
    return signer;
  }

  static Future<List<int>> _bytes(Dio dio, Uri url) async {
    final res = await dio.get<List<int>>(
      url.toString(),
      options: Options(responseType: ResponseType.bytes),
    );
    return res.data ?? const [];
  }

  /// One extension of an `index_v2` store; null when it is not usable.
  static ExtensionMeta? fromStore(
    StoreExtension e, {
    required String repoUrl,
    required String signer,
  }) {
    if (e.pkg.isEmpty || e.apkUrl.isEmpty || e.sources.isEmpty) return null;
    final languages = {for (final s in e.sources) s.lang}.toList();
    return ExtensionMeta(
      id: ExtensionMeta.mihonExtensionId(e.pkg),
      name: e.name.replaceFirst('Tachiyomi: ', ''),
      lang: languages.length == 1 ? languages.single : 'all',
      version: e.versionName,
      apiVersion: 1,
      baseUrl: e.sources.first.baseUrl,
      file: e.apkUrl,
      sha256: '',
      nsfw: e.nsfw,
      repoUrl: repoUrl,
      languages: languages.length > 1 ? languages : const [],
      icon: e.iconUrl.isEmpty ? null : e.iconUrl,
      pkg: e.pkg,
      signer: signer.toLowerCase(),
      versionCode: e.versionCode,
      mihonSources: e.sources,
    );
  }

  /// One `index.min.json` entry; null when it is not usable.
  static ExtensionMeta? entry(
    Map<String, dynamic> json, {
    required String repoUrl,
    required String signer,
  }) {
    final pkg = json['pkg'];
    final apk = json['apk'];
    if (pkg is! String || apk is! String) return null;
    final sources = [
      for (final s in (json['sources'] as List?) ?? const [])
        if (s is Map) MihonSourceRef.fromJson(s.cast<String, dynamic>()),
    ];
    final languages = {for (final s in sources) s.lang}.toList();
    return ExtensionMeta(
      id: ExtensionMeta.mihonExtensionId(pkg),
      name: '${json['name'] ?? pkg}'.replaceFirst('Tachiyomi: ', ''),
      lang: json['lang'] as String? ?? 'all',
      version: '${json['version'] ?? '0.0.0'}',
      apiVersion: 1,
      baseUrl: sources.firstOrNull?.baseUrl ?? '',
      file: 'apk/$apk',
      sha256: '',
      nsfw: json['nsfw'] == 1 || json['nsfw'] == true,
      repoUrl: repoUrl,
      languages: languages.length > 1 ? languages : const [],
      icon: 'icon/$pkg.png',
      pkg: pkg,
      signer: signer.toLowerCase(),
      versionCode: (json['code'] as num?)?.toInt() ?? 0,
      mihonSources: sources,
    );
  }
}
