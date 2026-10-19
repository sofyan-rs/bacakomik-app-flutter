import 'package:bacakomik_app/core/constants/variables.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:hive_ce/hive.dart';
import 'package:injectable/injectable.dart';

@module
abstract class RegisterModule {
  @lazySingleton
  Dio get dio => Dio(
        BaseOptions(
          baseUrl: AppVariables.baseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 30),
          responseType: ResponseType.json,
        ),
      );

  @lazySingleton
  Connectivity get connectivity => Connectivity();

  /// Initialised with a directory in main() before DI is configured.
  @lazySingleton
  HiveInterface get hive => Hive;
}
