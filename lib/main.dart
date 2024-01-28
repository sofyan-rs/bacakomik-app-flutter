import 'package:bacakomik_app/core/bloc/comic_details_bloc/comic_details_bloc.dart';
import 'package:bacakomik_app/core/bloc/home_bloc/home_bloc.dart';
import 'package:bacakomik_app/core/constants/variables.dart';
import 'package:bacakomik_app/data/data_provider/comic_details_data_provider.dart';
import 'package:bacakomik_app/data/data_provider/home_data_provider.dart';
import 'package:bacakomik_app/data/repository/comic_details_repository.dart';
import 'package:bacakomik_app/data/repository/home_repository.dart';
import 'package:flutter/material.dart';
import 'package:bacakomik_app/core/bloc/latest_more_bloc/latest_more_bloc.dart';
import 'package:bacakomik_app/core/constants/theme.dart';
import 'package:bacakomik_app/core/router/app_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bacakomik_app/data/data_provider/latest_data_provider.dart';
import 'package:bacakomik_app/data/repository/latest_repository.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  final router = AppRouter().router;

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
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: AppVariables.appName,
        theme: AppThemes.darkTheme,
        themeMode: ThemeMode.dark,
        routerDelegate: router.routerDelegate,
        routeInformationParser: router.routeInformationParser,
        routeInformationProvider: router.routeInformationProvider,
      ),
    );
  }
}
