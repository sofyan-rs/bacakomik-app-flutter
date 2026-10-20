import 'package:bacakomik_app/core/constants/variables.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:hive_ce/hive.dart';
import 'package:injectable/injectable.dart';

/// Name of the [Dio] used for file downloads.
const filesDio = 'files_dio';

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

  /// No base URL and a long receive timeout; chapter pages can be several
  /// megabytes each.
  @lazySingleton
  @Named(filesDio)
  Dio get fileDio => Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(minutes: 2),
        ),
      );

  @lazySingleton
  Connectivity get connectivity => Connectivity();

  /// Initialised with a directory in main() before DI is configured.
  @lazySingleton
  HiveInterface get hive => Hive;
}
