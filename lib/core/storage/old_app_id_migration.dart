import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// The app's id before it was renamed to Yoru (2.17.0).
const oldAppId = 'org.kurodev.bacakomik';

/// The app's id since 2.17.0.
const appId = 'org.kurodev.yoru';

/// Windows names the data folder `%APPDATA%\<CompanyName>\<ProductName>`
/// from Runner.rc; ProductName was BacaKomik until 2.17.2.
const oldWindowsProductName = 'BacaKomik';
const windowsProductName = 'Yoru';

/// Moves the library left under the app's old name to the new data folder,
/// on the first start after the rename, before Hive opens anything:
/// - macOS and Linux name the folder after the app id, so
///   `…/org.kurodev.bacakomik` moves to `…/org.kurodev.yoru` (debug builds,
///   `org.kurodev.yoru.debug`, move their own folder);
/// - Windows moves `%APPDATA%\kurodev\BacaKomik` to `%APPDATA%\kurodev\Yoru`.
///
/// Android and iOS keep each app's data apart, so there the library comes
/// over through a backup file or Drive sync.
Future<void> moveDataFromOldAppId() async {
  if (!Platform.isMacOS && !Platform.isLinux && !Platform.isWindows) return;
  try {
    final current = await getApplicationSupportDirectory();
    final old = oldDataFolder(current.path, windows: Platform.isWindows);
    if (old == null) return;
    moveDataFolder(Directory(old), current);
  } catch (e) {
    debugPrint('Data folder not moved from the old app name: $e');
  }
}

/// Moves [old] to [current] when [old] exists and [current] holds nothing.
/// path_provider creates [current]; anything in it means the app already
/// ran under the new name, and that data wins.
@visibleForTesting
void moveDataFolder(Directory old, Directory current) {
  if (!old.existsSync()) return;
  if (current.existsSync()) {
    if (current.listSync().isNotEmpty) return;
    current.deleteSync();
  }
  old.renameSync(current.path);
}

/// The folder [current] had under the app's old name, or null when
/// [current] is not named after the new one. [windows] picks the Windows
/// naming (product name) over the app id one.
@visibleForTesting
String? oldDataFolder(String current, {bool windows = false}) {
  final sep = Platform.pathSeparator;
  final trimmed = current.endsWith(sep)
      ? current.substring(0, current.length - 1)
      : current;
  final cut = trimmed.lastIndexOf(sep);
  final parent = trimmed.substring(0, cut + 1);
  final name = trimmed.substring(cut + 1);
  if (windows) {
    return name == windowsProductName ? '$parent$oldWindowsProductName' : null;
  }
  if (name != appId && !name.startsWith('$appId.')) return null;
  return '$parent$oldAppId${name.substring(appId.length)}';
}
