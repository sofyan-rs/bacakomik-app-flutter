part of 'app_router.dart';

GoRoute _comicDetail(String name, String path) {
  dynamic routePath = path;
  if (path.startsWith('/')) {
    routePath = null;
  }

  return GoRoute(
    name: '$name/${RouteConstants.comicDetails}',
    path: routePath != null
        ? routePath + RouteConstants.comicDetailsPath
        : RouteConstants.comicDetailsPath,
    builder: (context, state) {
      final slug = state.pathParameters['slug']!;
      final extra = state.extra as ComicDetailsExtraModel;
      return ComicDetailsScreen(
        slug: slug,
        title: extra.title,
        cover: extra.cover,
      );
    },
  );
}

final _latestChapter = GoRoute(
  name: RouteConstants.latestChapter,
  path: RouteConstants.latestChapterPath,
  builder: (context, state) => const LatestChapterScreen(),
  routes: [
    _comicDetail(
      RouteConstants.latestChapter,
      RouteConstants.latestChapterPath,
    ),
  ],
);
