class AppVariables {
  static const String appName = 'BacaKomik';
  static const String appDescription =
      'Aplikasi ini dikembangkan oleh KoiDevz menggunakan Flutter.';
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8788',
  );

  static const String reportLink =
      'https://github.com/sofyan-rs/bacakomik-app-release/issues/new';
}
