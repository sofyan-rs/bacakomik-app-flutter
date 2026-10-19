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

  /// Comic image hosts reject requests without this referer.
  static const String imageReferer = 'https://v9.voratoon.com/';

  /// Headers for every comic image request (covers, pages, saved images).
  static const Map<String, String> imageHeaders = {'Referer': imageReferer};

  static const String reportLink =
      'https://github.com/sofyan-rs/bacakomik-app-release/issues/new';
}
