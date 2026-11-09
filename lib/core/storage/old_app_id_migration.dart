import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// The app's id before it was renamed to Yoru (2.17.0).
const oldAppId = 'org.kurodev.bacakomik';

/// The app's id since 2.17.0.
const appId = 'org.kurodev.yoru';

/// On macOS and Linux the app data folder is named after the app id, so the
/// rename left the library in `…/org.kurodev.bacakomik`. On the first start
/// with the new id, that folder is moved to the new place, before Hive opens
/// anything. Debug builds (`org.kurodev.yoru.debug`) move their own folder.
///
/// Windows names the folder after `ProductName` in Runner.rc, which did not
/// change. Android and iOS keep each app's data apart, so there the library
/// comes over through a backup file or Drive sync.
Future<void> moveDataFromOldAppId() async {
  if (!Platform.isMacOS && !Platform.isLinux) return;
  try {
    final current = await getApplicationSupportDirectory();
    final old = oldDataFolder(current.path);
    if (old == null) return;
    final oldDir = Directory(old);
    if (!oldDir.existsSync()) return;
    // path_provider creates the new folder; anything in it means the app
    // already ran with the new id, and that data wins.
    if (current.existsSync()) {
      if (current.listSync().isNotEmpty) return;
      current.deleteSync();
    }
    oldDir.renameSync(current.path);
  } catch (e) {
    debugPrint('Data folder not moved from $oldAppId: $e');
  }
}

/// The folder [current] had under the old id, or null when [current] is not
/// named after the new id.
@visibleForTesting
String? oldDataFolder(String current) {
  final sep = Platform.pathSeparator;
  final trimmed = current.endsWith(sep)
      ? current.substring(0, current.length - 1)
      : current;
  final cut = trimmed.lastIndexOf(sep);
  final name = trimmed.substring(cut + 1);
  if (name != appId && !name.startsWith('$appId.')) return null;
  return '${trimmed.substring(0, cut + 1)}$oldAppId${name.substring(appId.length)}';
}
