import 'package:bacakomik_app/core/constants/variables.dart';
import 'package:bacakomik_app/core/source/comic_key.dart';

/// Shareable HTTPS links that open the app (Android App Links), e.g.
/// `https://bacakomik.kurodev.org/series/magic-emperor`.
abstract final class DeepLinks {
  static const _comicPath = 'series';

  static Uri comic(String slug) =>
      Uri.https(AppVariables.linkHost, '/$_comicPath/$slug');

  /// The series slug of a comic link, or null for any other link.
  static String? comicSlug(Uri uri) {
    if (uri.host != AppVariables.linkHost) return null;
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.length != 2 || segments.first != _comicPath) return null;
    return segments.last;
  }

  /// Placeholder title from a comic key while the details load:
  /// `magic-emperor` and `voratoon:magic-emperor` → `Magic Emperor`.
  static String titleFromSlug(String key) => ComicKey.slugOf(key)
      .split('-')
      .where((w) => w.isNotEmpty)
      .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}
