import 'package:bacakomik_app/app/root_tabs.dart';
import 'package:bacakomik_app/app/splash_screen.dart';
import 'package:bacakomik_app/core/theme/dotline_theme.dart';
import 'package:bacakomik_app/core/constants/variables.dart';
import 'package:bacakomik_app/core/di/injection.dart';
import 'package:bacakomik_app/features/backup/presentation/bloc/backup_cubit.dart';
import 'package:bacakomik_app/features/bookmark/presentation/bloc/bookmark_cubit.dart';
import 'package:bacakomik_app/features/download/presentation/bloc/download_cubit.dart';
import 'package:bacakomik_app/features/explore/presentation/bloc/explore_bloc.dart';
import 'package:bacakomik_app/features/explore/presentation/bloc/filter_cubit.dart';
import 'package:bacakomik_app/features/history/presentation/bloc/history_cubit.dart';
import 'package:bacakomik_app/features/home/presentation/bloc/home_bloc.dart';
import 'package:bacakomik_app/features/settings/domain/entities/app_settings.dart';
import 'package:bacakomik_app/features/settings/presentation/bloc/settings_cubit.dart';
import 'package:bacakomik_app/features/sync/presentation/bloc/sync_cubit.dart';
import 'package:bacakomik_app/features/update/presentation/bloc/update_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// App-wide blocs: the bottom-navigation tabs and the user's library.
/// Screen-specific blocs are provided by their own routes. [RootTabs] sits
/// above the navigator so pushed routes can switch tabs.
class BacaKomikApp extends StatefulWidget {
  const BacaKomikApp({super.key});

  @override
  State<BacaKomikApp> createState() => _BacaKomikAppState();
}

class _BacaKomikAppState extends State<BacaKomikApp> {
  final _tabs = RootTabs();

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<HomeBloc>()),
        BlocProvider(create: (_) => getIt<ExploreBloc>()),
        BlocProvider(create: (_) => getIt<FilterCubit>()),
        BlocProvider(create: (_) => getIt<BookmarkCubit>()..load()),
        BlocProvider(create: (_) => getIt<HistoryCubit>()..load()),
        BlocProvider(create: (_) => getIt<SettingsCubit>()..load()),
        BlocProvider(create: (_) => getIt<DownloadCubit>()..load()),
        BlocProvider(create: (_) => getIt<BackupCubit>()),
        BlocProvider(create: (_) => getIt<UpdateCubit>()),
        BlocProvider(create: (_) => getIt<SyncCubit>()..start(), lazy: false),
      ],
      child: BlocListener<SyncCubit, SyncState>(
        listenWhen: (previous, current) =>
            previous.libraryRevision != current.libraryRevision,
        listener: (context, _) {
          context.read<BookmarkCubit>().load();
          context.read<HistoryCubit>().load();
        },
        child: RootTabsScope(
          tabs: _tabs,
          child: BlocBuilder<SettingsCubit, AppSettings>(
            builder: (context, settings) {
              return MaterialApp(
                debugShowCheckedModeBanner: false,
                title: AppVariables.appName,
                theme: DotlineThemes.light,
                darkTheme: DotlineThemes.dark,
                themeMode: switch (settings.themeMode) {
                  AppThemeMode.dark => ThemeMode.dark,
                  AppThemeMode.light => ThemeMode.light,
                  AppThemeMode.system => ThemeMode.system,
                },
                home: const SplashScreen(),
              );
            },
          ),
        ),
      ),
    );
  }
}
