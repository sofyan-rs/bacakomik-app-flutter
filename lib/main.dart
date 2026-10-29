import 'dart:async';
import 'dart:io';

import 'package:bacakomik_app/app/app.dart';
import 'package:bacakomik_app/core/di/injection.dart';
import 'package:bacakomik_app/core/network/cover_cache_migration.dart';
import 'package:bacakomik_app/core/network/image_cache.dart';
import 'package:bacakomik_app/core/source/extension_manager.dart';
import 'package:bacakomik_app/core/storage/box_recovery.dart';
import 'package:bacakomik_app/core/storage/hive_boxes.dart';
import 'package:bacakomik_app/features/bookmark/data/datasources/bookmark_local_data_source.dart';
import 'package:bacakomik_app/features/download/data/datasources/download_local_data_source.dart';
import 'package:bacakomik_app/features/history/data/datasources/history_local_data_source.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';
import 'package:path_provider/path_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Desktop documents folders belong to the user, not to app data.
  hiveDirectory =
      (Platform.isAndroid || Platform.isIOS
              ? await getApplicationDocumentsDirectory()
              : await getApplicationSupportDirectory())
          .path;
  Hive.init(hiveDirectory);
  await configureDependencies();
  // Sources must exist before the first screen loads comics.
  final extensions = getIt<ExtensionManager>();
  await extensions.installBundled();
  runApp(const BacaKomikApp());
  // In the background: finds extension updates for the badge in More.
  unawaited(extensions.catalog());
  unawaited(_moveCoversToCoverCache());
  // Starts Chromium while idle, so the first cookie read is not mid-scroll.
  unawaited(warmUpWebView());
}

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
