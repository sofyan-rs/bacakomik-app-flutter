// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'package:bacakomik_app/core/di/register_module.dart' as _i600;
import 'package:bacakomik_app/core/network/api_client.dart' as _i430;
import 'package:bacakomik_app/core/network/network_info.dart' as _i764;
import 'package:connectivity_plus/connectivity_plus.dart' as _i895;
import 'package:dio/dio.dart' as _i361;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final registerModule = _$RegisterModule();
    gh.lazySingleton<_i361.Dio>(() => registerModule.dio);
    gh.lazySingleton<_i895.Connectivity>(() => registerModule.connectivity);
    gh.lazySingleton<_i430.ApiClient>(() => _i430.ApiClient(gh<_i361.Dio>()));
    gh.lazySingleton<_i764.NetworkInfo>(
      () => _i764.NetworkInfoImpl(gh<_i895.Connectivity>()),
    );
    return this;
  }
}

class _$RegisterModule extends _i600.RegisterModule {}
