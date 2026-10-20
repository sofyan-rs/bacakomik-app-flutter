import 'dart:io';

import 'package:bacakomik_app/core/di/register_module.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:path_provider/path_provider.dart';

/// Files of downloaded chapters:
///
/// ```
/// <root>/<comicSlug>/cover.<ext>
/// <root>/<comicSlug>/<chapterNumber>/000.<ext>
/// ```
///
/// Paths given to and returned by this class are relative to the root.
abstract interface class DownloadFileDataSource {
  String comicDir(String comicSlug);

  String chapterDir(String comicSlug, String chapterNumber);

  /// Downloads [url] to `[pathWithoutExtension].<ext>`, through a `.part`
  /// file so an interrupted download never looks complete.
  Future<({String path, int size})> download(
    String url,
    String pathWithoutExtension, {
    CancelToken? cancelToken,
  });

  Future<String> absolute(String path);

  Future<bool> exists(String path);

  /// Deletes a file or a folder with everything in it.
  Future<void> delete(String path);

  Future<void> deleteAll();
}

@LazySingleton(as: DownloadFileDataSource)
class DownloadFileDataSourceImpl implements DownloadFileDataSource {
  DownloadFileDataSourceImpl(@Named(filesDio) this._dio);

  static const _imageExtensions = {'jpg', 'jpeg', 'png', 'webp', 'gif', 'avif'};

  final Dio _dio;
  Future<String>? _root;

  /// App-specific external storage on Android (no permission needed,
  /// removed on uninstall), else the application support directory.
  Future<String> get root => _root ??= () async {
    Directory? base;
    if (Platform.isAndroid) base = await getExternalStorageDirectory();
    base ??= await getApplicationSupportDirectory();
    return '${base.path}/downloads';
  }();

  @override
  String comicDir(String comicSlug) => _segment(comicSlug);

  @override
  String chapterDir(String comicSlug, String chapterNumber) =>
      '${comicDir(comicSlug)}/${_segment(chapterNumber)}';

  @override
  Future<({String path, int size})> download(
    String url,
    String pathWithoutExtension, {
    CancelToken? cancelToken,
  }) async {
    final root = await this.root;
    final part = File('$root/$pathWithoutExtension.part');
    await part.parent.create(recursive: true);
    final response = await _dio.download(
      url,
      part.path,
      cancelToken: cancelToken,
    );
    final extension =
        _extensionOfUrl(url) ??
        _extensionOfType(response.headers.value(Headers.contentTypeHeader)) ??
        'jpg';
    final path = '$pathWithoutExtension.$extension';
    final file = await part.rename('$root/$path');
    return (path: path, size: await file.length());
  }

  @override
  Future<String> absolute(String path) async => '${await root}/$path';

  @override
  Future<bool> exists(String path) async => File(await absolute(path)).exists();

  @override
  Future<void> delete(String path) async {
    final absolute = await this.absolute(path);
    if (await Directory(absolute).exists()) {
      await Directory(absolute).delete(recursive: true);
    } else if (await File(absolute).exists()) {
      await File(absolute).delete();
    }
  }

  @override
  Future<void> deleteAll() async {
    final dir = Directory(await root);
    if (await dir.exists()) await dir.delete(recursive: true);
  }

  /// Slugs are URL-safe already; this keeps a bad one inside the root.
  static String _segment(String value) {
    final safe = value.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    return safe.isEmpty || safe == '.' || safe == '..' ? '_' : safe;
  }

  static String? _extensionOfUrl(String url) {
    final segments = Uri.tryParse(url)?.pathSegments ?? const <String>[];
    if (segments.isEmpty) return null;
    final name = segments.last;
    final dot = name.lastIndexOf('.');
    if (dot < 0) return null;
    final extension = name.substring(dot + 1).toLowerCase();
    return _imageExtensions.contains(extension) ? extension : null;
  }

  static String? _extensionOfType(String? contentType) {
    if (contentType == null) return null;
    final subtype = contentType.split(';').first.split('/').last.trim();
    final extension = subtype == 'jpeg' ? 'jpg' : subtype.toLowerCase();
    return _imageExtensions.contains(extension) ? extension : null;
  }
}
