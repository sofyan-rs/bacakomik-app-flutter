class AppVariables {
  static const String appName = 'Yoru';
  static const String appDescription =
      'This app is developed by Kurodev with Flutter.';
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api-bacakomik.kurodev.org',
  );

  static const String websiteLink = 'https://kurodev.org';
  static const String websiteLabel = 'kurodev.org';

  /// Host of shared comic links. Its `/.well-known/assetlinks.json` lets
  /// Android open them in the app; see `hosting/`.
  static const String linkHost = 'yoru.kurodev.org';

  /// Host of links shared before the app was renamed to Yoru (2.17.0).
  /// They still open the app.
  static const String oldLinkHost = 'bacakomik.kurodev.org';

  /// OAuth client of type "Web application" in the Google Cloud project;
  /// Android sign-in needs it as the server client id. The Android clients
  /// are matched by package name and signing SHA-1. iOS uses its own client
  /// (bundle id `org.kurodev.yoru`): `GIDClientID` and its reversed id as a
  /// URL scheme in ios/Runner/Info.plist.
  static const String googleServerClientId =
      '805931733064-tmhv2feicbtujdn9snfbp0e30liidr91.apps.googleusercontent.com';

  /// OAuth client of type "Desktop app" in the same project, for sign-in in
  /// the browser on Windows, macOS and Linux. Google treats a desktop
  /// client's secret as public; it is passed at build time
  /// (`--dart-define`) only to keep it out of the repo. Empty: no sync.
  static const String googleDesktopClientId = String.fromEnvironment(
    'GOOGLE_DESKTOP_CLIENT_ID',
  );
  static const String googleDesktopClientSecret = String.fromEnvironment(
    'GOOGLE_DESKTOP_CLIENT_SECRET',
  );

  static const String githubRepo = 'sofyan-rs/yoru-comic-app';
  static const String reportLink = 'https://github.com/$githubRepo/issues/new';
  static const String latestReleaseApi =
      'https://api.github.com/repos/$githubRepo/releases/latest';
}
