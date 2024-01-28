import 'package:bacakomik_app/core/bloc/chapter_read_bloc/chapter_read_bloc.dart';
import 'package:bacakomik_app/core/bloc/comic_details_bloc/comic_details_bloc.dart';
import 'package:bacakomik_app/core/bloc/home_bloc/home_bloc.dart';
import 'package:bacakomik_app/core/constants/variables.dart';
import 'package:bacakomik_app/data/data_provider/chapter_read_data_provider.dart';
import 'package:bacakomik_app/data/data_provider/comic_details_data_provider.dart';
import 'package:bacakomik_app/data/data_provider/home_data_provider.dart';
import 'package:bacakomik_app/data/repository/chapter_read_repository.dart';
import 'package:bacakomik_app/data/repository/comic_details_repository.dart';
import 'package:bacakomik_app/data/repository/home_repository.dart';
import 'package:bacakomik_app/presentation/screens/initial/splash/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:bacakomik_app/core/bloc/latest_more_bloc/latest_more_bloc.dart';
import 'package:bacakomik_app/core/constants/theme.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bacakomik_app/data/data_provider/latest_data_provider.dart';
import 'package:bacakomik_app/data/repository/latest_repository.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => HomeBloc(
            HomeRepository(
              HomeDataProvider(),
            ),
          ),
        ),
        BlocProvider(
          create: (context) => LatestMoreBloc(
            LatestRepository(
              LatestDataProvider(),
            ),
          ),
        ),
        BlocProvider(
          create: (context) => ComicDetailsBloc(
            ComicDetailsRepository(
              ComicDetailsDataProvider(),
            ),
          ),
        ),
        BlocProvider(
          create: (context) => ChapterReadBloc(
            ChapterReadRepository(
              ChapterReadDataProvider(),
            ),
          ),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: AppVariables.appName,
        theme: AppThemes.darkTheme,
        themeMode: ThemeMode.dark,
        home: const SplashScreen(),
      ),
    );
  }
}
