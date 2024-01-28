import 'package:bacakomik_app/core/router/models/comic_details_extra_model.dart';
import 'package:go_router/go_router.dart';
import 'package:bacakomik_app/presentation/screens/initial/splash/splash_screen.dart';
import 'package:bacakomik_app/presentation/screens/sub/latest_chapter/latest_chapter_screen.dart';
import 'package:bacakomik_app/presentation/widgets/tabs/main_tabs.dart';
import 'package:bacakomik_app/presentation/screens/sub/comic_details/comic_details_screen.dart';

part 'route_constants.dart';
part 'child_route.dart';

class AppRouter {
  final router = GoRouter(
    initialLocation: RouteConstants.splashPath,
    routes: [
      GoRoute(
        name: RouteConstants.splash,
        path: RouteConstants.splashPath,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        name: RouteConstants.root,
        path: RouteConstants.rootPath,
        builder: (context, state) => const MainTabs(),
        routes: [
          _latestChapter,
          _comicDetail(
            RouteConstants.root,
            RouteConstants.rootPath,
          ),
        ],
      ),
      // GoRoute(
      //   name: 'explore',
      //   path: '/explore',
      //   builder: (context, state) => const MainTabs(),
      // ),
      // GoRoute(
      //   name: 'favorites',
      //   path: '/favorites',
      //   builder: (context, state) => const MainTabs(),
      // ),
      // GoRoute(
      //   name: 'more',
      //   path: '/more',
      //   builder: (context, state) => const MainTabs(),
      // ),
    ],
  );
}
