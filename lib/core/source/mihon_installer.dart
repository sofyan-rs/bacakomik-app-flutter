import 'dart:io';

import 'package:bacakomik_app/core/error/exceptions.dart';
import 'package:bacakomik_app/core/source/extension_meta.dart';
import 'package:bacakomik_app/core/source/mihon_host.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

/// Installs Mihon extension APKs for [ExtensionManager]. An APK lives in
/// `<app support>/extensions/<id>-<versionCode>-<time>.apk`, read-only (Android
/// refuses to run code from a writable file); a new version gets a new
/// file, so the one a loaded extension runs from is never overwritten.
class MihonInstaller {
  MihonInstaller(this._dio, this._host);

  final Dio _dio;
  final MihonHost _host;

  /// Downloads [meta]'s APK, checks it is signed with the repo's key and
  /// runs on this host, and hands it to the host. Returns [meta] with the
  /// sources the APK really holds.
  Future<ExtensionMeta> install(ExtensionMeta meta) async {
    final pkg = meta.pkg!;
    final signer = meta.signer;
    final repoUrl = meta.repoUrl;
    if (signer == null || repoUrl == null) {
      throw const ServerException('Unknown extension repo');
    }
    if (!await _host.available) {
      throw const ServerException('Mihon extensions need Android 9 or newer');
    }
    final dir = await _dir();
    await dir.create(recursive: true);
    // A name of its own per install: reinstalling the same version (or two
    // installs at once) never touches the file a loaded extension runs from.
    final stamp = DateTime.now().microsecondsSinceEpoch;
    final apk = File(_join(dir, '${meta.id}-${meta.versionCode}-$stamp.apk'));
    final part = File('${apk.path}.part');
    try {
      await _dio.download(
        Uri.parse(repoUrl).resolve(meta.file).toString(),
        part.path,
      );
      await part.rename(apk.path);
      final info = await _host.handle('inspect', {
        'path': apk.path,
        'signer': signer,
      });
      if (info is! Map || info['pkg'] != pkg) {
        throw const ServerException(
          'The file is not the extension it should be',
        );
      }
      if (info['supported'] != true) {
        throw ServerException(
          'This extension uses lib ${info['lib']}, which BacaKomik does not run yet',
        );
      }
      final installed = await _host.handle('install', {
        'pkg': pkg,
        'apk': apk.path,
        'signer': signer,
      });
      final sources = [
        for (final s in installed is List ? installed : const [])
          if (s is Map) MihonSourceRef.fromJson(s.cast<String, dynamic>()),
      ];
      if (sources.isEmpty) {
        throw const ServerException('The extension has no sources');
      }
      await _deleteOthers(meta.id, keep: apk.path);
      return _withSources(meta, sources);
    } catch (_) {
      if (await part.exists()) await part.delete();
      if (await apk.exists()) await apk.delete();
      rethrow;
    }
  }

  Future<void> uninstall(ExtensionMeta meta) async {
    // A device that can't run it holds nothing to unload: just the files.
    if (meta.pkg case final pkg? when await _host.available) {
      try {
        await _host.handle('uninstall', {'pkg': pkg});
      } on ServerException catch (e) {
        if (e.statusCode != 501) rethrow;
      }
    }
    await _deleteOthers(meta.id);
  }

  Future<void> _deleteOthers(String id, {String? keep}) async {
    final dir = await _dir();
    if (!await dir.exists()) return;
    await for (final f in dir.list()) {
      final name = f.uri.pathSegments.last;
      if (f is File &&
          f.path != keep &&
          name.startsWith('$id-') &&
          name.endsWith('.apk')) {
        await f.delete();
      }
    }
  }

  static ExtensionMeta _withSources(
    ExtensionMeta m,
    List<MihonSourceRef> sources,
  ) {
    final languages = {for (final s in sources) s.lang}.toList();
    return ExtensionMeta(
      id: m.id,
      name: m.name,
      lang: m.lang,
      version: m.version,
      apiVersion: m.apiVersion,
      baseUrl: sources.first.baseUrl.isEmpty
          ? m.baseUrl
          : sources.first.baseUrl,
      file: m.file,
      sha256: m.sha256,
      nsfw: m.nsfw,
      repoUrl: m.repoUrl,
      languages: languages.length > 1 ? languages : const [],
      icon: m.icon,
      pkg: m.pkg,
      signer: m.signer,
      versionCode: m.versionCode,
      mihonSources: sources,
    );
  }

  static Future<Directory> _dir() async {
    final support = await getApplicationSupportDirectory();
    return Directory(_join(support, 'extensions'));
  }

  static String _join(Directory dir, String name) =>
      '${dir.path}${Platform.pathSeparator}$name';
}
