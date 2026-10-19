import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';

import 'package:bacakomik_app/core/bloc/chapter_read_bloc/chapter_read_bloc.dart';
import 'package:bacakomik_app/core/bloc/comic_details_bloc/comic_details_bloc.dart';
import 'package:bacakomik_app/core/bloc/explore_bloc/explore_bloc.dart';
import 'package:bacakomik_app/core/bloc/bookmark_cubit/bookmark_cubit.dart';
import 'package:bacakomik_app/core/bloc/filter_cubit/filter_cubit.dart';
import 'package:bacakomik_app/core/bloc/history_cubit/history_cubit.dart';
import 'package:bacakomik_app/features/home/presentation/bloc/home_bloc.dart';
import 'package:bacakomik_app/core/bloc/latest_more_bloc/latest_more_bloc.dart';
import 'package:bacakomik_app/core/bloc/search_comic_bloc/search_comic_bloc.dart';
import 'package:bacakomik_app/core/bloc/settings_cubit/settings_cubit.dart';
import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:bacakomik_app/core/constants/theme.dart';
import 'package:bacakomik_app/core/constants/variables.dart';
import 'package:bacakomik_app/core/di/injection.dart';
import 'package:bacakomik_app/core/models/settings_model.dart';
import 'package:bacakomik_app/data/data_provider/bacakomik_data_provider.dart';
import 'package:bacakomik_app/data/repository/chapter_read_repository.dart';
import 'package:bacakomik_app/data/repository/comic_details_repository.dart';
import 'package:bacakomik_app/data/repository/explore_data_repository.dart';
import 'package:bacakomik_app/data/repository/latest_repository.dart';
import 'package:bacakomik_app/data/repository/search_repository.dart';
import 'package:bacakomik_app/presentation/screens/initial/splash/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  HydratedBloc.storage = await HydratedStorage.build(
    storageDirectory: HydratedStorageDirectory(
      (await getApplicationDocumentsDirectory()).path,
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final dataProvider = BacaKomikDataProvider();

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => getIt<HomeBloc>(),
        ),
        BlocProvider(
          create: (context) => LatestMoreBloc(
            LatestRepository(
              dataProvider,
            ),
          ),
        ),
        BlocProvider(
          create: (context) => SearchComicBloc(
            SearchRepository(
              dataProvider,
            ),
          ),
        ),
        BlocProvider(
          create: (context) => ComicDetailsBloc(
            ComicDetailsRepository(
              dataProvider,
            ),
          ),
        ),
        BlocProvider(
          create: (context) => ChapterReadBloc(
            ChapterReadRepository(
              dataProvider,
            ),
          ),
        ),
        BlocProvider(
          create: (context) => ExploreBloc(
            ExploreRepository(
              dataProvider,
            ),
          ),
        ),
        BlocProvider(
          create: (context) => BookmarkCubit(),
        ),
        BlocProvider(
          create: (context) => HistoryCubit(),
        ),
        BlocProvider(
          create: (context) => SettingsCubit(),
        ),
        BlocProvider(
          create: (context) => FilterCubit(),
        ),
      ],
      child: BlocBuilder<SettingsCubit, SettingsModel>(
        builder: (context, state) {
          final darkMode = state.darkMode;

          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: AppVariables.appName,
            theme: AppThemes.lightTheme,
            darkTheme: AppThemes.darkTheme,
            themeMode: darkMode == AppText.system
                ? ThemeMode.system
                : darkMode == AppText.dark
                    ? ThemeMode.dark
                    : ThemeMode.light,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
