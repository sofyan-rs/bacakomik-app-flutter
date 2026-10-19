import 'package:bacakomik_app/core/di/injection.config.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

final getIt = GetIt.instance;

/// Requires `Hive.init` first: Hive boxes are opened while resolving.
@InjectableInit()
Future<void> configureDependencies() => getIt.init();
