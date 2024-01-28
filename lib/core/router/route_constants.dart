part of 'app_router.dart';

class RouteConstants {
  /// Route for page [SplashScreen]
  static const String splash = 'splash';
  static const String splashPath = '/splash';

  /// Route for page [MainTabs]
  static const String root = 'root';
  static const String rootPath = '/';

  /// Route for page [LatestChapterScreen]
  static const String latestChapter = 'latestChapter';
  static const String latestChapterPath = 'latestChapter';

  /// Route for page [ComicDetailsScreen]
  static const String comicDetails = 'comicDetails';
  static const String comicDetailsPath = 'comicDetails/:slug';
}
