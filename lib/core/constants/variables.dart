class AppVariables {
  static const String appName = 'BacaKomik';
  static const String appDescription =
      'Aplikasi ini dikembangkan oleh Kurodev menggunakan Flutter.';
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api-bacakomik.kurodev.org',
  );

  static const String websiteLink = 'https://kurodev.org';
  static const String websiteLabel = 'kurodev.org';

  /// Host of shared comic links. Its `/.well-known/assetlinks.json` lets
  /// Android open them in the app; see `hosting/`.
  static const String linkHost = 'bacakomik.kurodev.org';

  /// OAuth client of type "Web application" in the Google Cloud project;
  /// Android sign-in needs it as the server client id. The Android clients
  /// are matched by package name and signing SHA-1.
  static const String googleServerClientId =
      '805931733064-tmhv2feicbtujdn9snfbp0e30liidr91.apps.googleusercontent.com';

  static const String githubRepo = 'sofyan-rs/bacakomik-app-flutter';
  static const String reportLink = 'https://github.com/$githubRepo/issues/new';
  static const String latestReleaseApi =
      'https://api.github.com/repos/$githubRepo/releases/latest';
}
