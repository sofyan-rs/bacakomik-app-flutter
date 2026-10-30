import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider/path_provider.dart';

/// Fails unless the app's data folder is the debug build's own. These tests
/// open, read and download comics, and the installed app on the same
/// machine must never share their data (macOS debug builds have their own
/// bundle id, `org.kurodev.bacakomik.debug`; see Configs/Debug.xcconfig).
Future<void> expectIsolatedData() async {
  final dir = (await getApplicationSupportDirectory()).path;
  if (!Platform.isMacOS || !dir.contains('org.kurodev.bacakomik.debug')) {
    fail('Refusing to run against $dir: it may be the installed app\'s data');
  }
}
