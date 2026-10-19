import 'dart:io';

import 'package:hive_ce/hive.dart';

/// Points Hive at a fresh temp directory. Returns a teardown callback.
Future<Future<void> Function()> setUpTempHive() async {
  final dir = await Directory.systemTemp.createTemp('bacakomik_hive_');
  Hive.init(dir.path);
  return () async {
    await Hive.close();
    await dir.delete(recursive: true);
  };
}
