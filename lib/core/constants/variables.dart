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

  static const String githubRepo = 'sofyan-rs/bacakomik-app-flutter';
  static const String reportLink = 'https://github.com/$githubRepo/issues/new';
  static const String latestReleaseApi =
      'https://api.github.com/repos/$githubRepo/releases/latest';
}
