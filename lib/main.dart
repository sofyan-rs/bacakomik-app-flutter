import 'package:bacakomik_app/app/app.dart';
import 'package:bacakomik_app/core/di/injection.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';
import 'package:path_provider/path_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Hive.init((await getApplicationDocumentsDirectory()).path);
  await configureDependencies();
  runApp(const BacaKomikApp());
}
