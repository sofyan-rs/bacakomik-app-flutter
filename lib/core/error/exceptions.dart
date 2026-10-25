/// Thrown by remote data sources when the API call fails.
class ServerException implements Exception {
  const ServerException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

/// A source answered with a bot check (e.g. Cloudflare) instead of data.
/// Travels as an error message `challenge: <url>`, which extensions can also
/// throw for their site's own checks; [urlOf] reads it back.
abstract final class Challenge {
  static const prefix = 'challenge: ';

  static String message(String url) => '$prefix$url';

  /// The page to open in the WebView, or null when [message] is not a
  /// challenge.
  static String? urlOf(String message) {
    final i = message.indexOf(prefix);
    if (i < 0) return null;
    final url = message.substring(i + prefix.length).trim().split(' ').first;
    return url.startsWith('http') ? url : null;
  }
}

/// Thrown by local data sources when stored data cannot be read or written.
class CacheException implements Exception {
  const CacheException(this.message);

  final String message;

  @override
  String toString() => message;
}
