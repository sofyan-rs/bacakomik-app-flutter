import 'dart:async';

import 'package:bacakomik_app/app/app.dart';
import 'package:bacakomik_app/core/di/injection.dart';
import 'package:bacakomik_app/core/source/extension_manager.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';
import 'package:path_provider/path_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Hive.init((await getApplicationDocumentsDirectory()).path);
  await configureDependencies();
  // Sources must exist before the first screen loads comics.
  final extensions = getIt<ExtensionManager>();
  await extensions.installBundled();
  runApp(const BacaKomikApp());
  // In the background: finds extension updates for the badge in More.
  unawaited(extensions.catalog());
}
