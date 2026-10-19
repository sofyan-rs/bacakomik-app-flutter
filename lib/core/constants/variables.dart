class AppVariables {
  static const String appName = 'BacaKomik';
  static const String appDescription =
      'Aplikasi ini dikembangkan oleh Kurodev menggunakan Flutter.';
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api-bacakomik.kurodev.org',
  );

  static const String reportLink =
      'https://github.com/sofyan-rs/bacakomik-app-release/issues/new';
}
