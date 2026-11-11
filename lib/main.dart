import 'dart:async';
import 'dart:io';

import 'package:yoru/app/app.dart';
import 'package:yoru/core/di/injection.dart';
import 'package:yoru/core/network/cover_cache_migration.dart';
import 'package:yoru/core/network/dns_setting.dart';
import 'package:yoru/core/network/doh.dart';
import 'package:yoru/core/network/image_cache.dart';
import 'package:yoru/core/utils/image_support.dart';
import 'package:yoru/core/source/comic_key.dart';
import 'package:yoru/core/source/extension_manager.dart';
import 'package:yoru/core/storage/box_recovery.dart';
import 'package:yoru/core/storage/hive_boxes.dart';
import 'package:yoru/core/storage/old_app_id_migration.dart';
import 'package:yoru/core/utils/cover_url.dart';
import 'package:yoru/core/usecase/usecase.dart';
import 'package:yoru/features/settings/domain/usecases/settings_usecases.dart';
import 'package:yoru/features/bookmark/data/models/bookmark_model.dart';
import 'package:yoru/features/bookmark/data/datasources/bookmark_local_data_source.dart';
import 'package:yoru/features/download/data/datasources/download_local_data_source.dart';
import 'package:yoru/features/download/data/models/downloaded_chapter_model.dart';
import 'package:yoru/features/history/data/datasources/history_local_data_source.dart';
import 'package:yoru/features/history/data/models/read_history_model.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';
import 'package:path_provider/path_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Before any HttpClient exists, so all of them can use DNS over HTTPS.
  HttpOverrides.global = DohHttpOverrides();
  await moveDataFromOldAppId();
  // Desktop documents folders belong to the user, not to app data.
  hiveDirectory =
      (Platform.isAndroid || Platform.isIOS
              ? await getApplicationDocumentsDirectory()
              : await getApplicationSupportDirectory())
          .path;
  Hive.init(hiveDirectory);
  await configureDependencies();
  // Before the first request: bundled extensions and the catalog go online.
  final settings = await getIt<GetSettings>()(const NoParams());
  await applyDnsOverHttps(settings.fold((_) => '', (s) => s.dnsOverHttps));
  // Sources must exist before the first screen loads comics.
  final extensions = getIt<ExtensionManager>();
  await extensions.installBundled();
  // Image hosts' headers (e.g. a CDN's Referer) before the first cover.
  _syncImageHostHeaders(extensions);
  extensions.addListener(() => _syncImageHostHeaders(extensions));
  await _fixRelativeCovers(extensions);
  runApp(const YoruApp());
  // Before the first images: whether to ask image hosts for AVIF.
  unawaited(avifSupported());
  // In the background: finds extension updates for the badge in More.
  unawaited(extensions.catalog());
  unawaited(_moveCoversToCoverCache());
  // Starts Chromium while idle, so the first cookie read is not mid-scroll.
  unawaited(warmUpWebView());
}

/// Hands the installed extensions' `imageHosts` and `imageHeaders` to the
/// image caches.
void _syncImageHostHeaders(ExtensionManager extensions) =>
    imageHostHeaders.update([
      for (final e in extensions.extensions)
        (hosts: e.imageHosts, headers: e.imageHeaders),
    ]);

/// Once, a little after start: library covers cached before the cover cache
/// existed are copied into it (see [CoverCacheMigration]).
Future<void> _moveCoversToCoverCache() async {
  final migration = CoverCacheMigration(
    pages: comicImageCache,
    covers: coverImageCache,
    flags: getIt<Box<String>>(instanceName: HiveBoxes.settings),
    coverUrls: () => [
      for (final b in getIt<BookmarkLocalDataSource>().getAll())
        b.comicDetails.coverImg,
      for (final c in getIt<HistoryLocalDataSource>().getComics().values)
        c.comicDetails.coverImg,
      for (final c in getIt<DownloadLocalDataSource>().getComics().values)
        c.comicDetails.coverImg,
    ],
  );
  if (migration.done) return;
  await Future<void>.delayed(const Duration(seconds: 3));
  try {
    await migration.run();
  } catch (e) {
    debugPrint('Cover cache migration failed: $e');
  }
}

/// Once: covers saved as paths on the site (Comix sent those before the app
/// resolved them, see [absoluteCover]) get the source's host, in bookmarks,
/// history and downloads.
Future<void> _fixRelativeCovers(ExtensionManager extensions) async {
  const doneKey = 'relativeCoversFixed';
  final flags = getIt<Box<String>>(instanceName: HiveBoxes.settings);
  if (flags.get(doneKey) != null) return;
  try {
    // The stored JSON with the cover resolved; null when it needs nothing.
    Map<String, dynamic>? fixed(String key, Map<String, dynamic> json) {
      final details = json['comicDetails'] as Map<String, dynamic>;
      final cover = details['coverImg'] as String? ?? '';
      final base = extensions.meta(ComicKey.sourceOf(key))?.baseUrl ?? '';
      final resolved = absoluteCover(cover, base);
      if (resolved == cover) return null;
      return {
        ...json,
        'comicDetails': {...details, 'coverImg': resolved},
      };
    }

    final bookmarks = getIt<BookmarkLocalDataSource>();
    await bookmarks.putAll([
      for (final b in bookmarks.getAll())
        if (fixed(b.slug, b.toJson()) case final json?)
          BookmarkModel.fromJson(json),
    ]);
    final history = getIt<HistoryLocalDataSource>();
    await history.putComics([
      for (final c in history.getComics().values)
        if (fixed(c.slug, c.toJson()) case final json?)
          HistoryComicModel.fromJson(json),
    ]);
    final downloads = getIt<DownloadLocalDataSource>();
    for (final c in downloads.getComics().values) {
      if (fixed(c.slug, c.toJson()) case final json?) {
        await downloads.putComic(DownloadComicModel.fromJson(json));
      }
    }
    await flags.put(doneKey, DateTime.now().toIso8601String());
  } catch (e) {
    debugPrint('Relative covers not fixed: $e');
  }
}
