import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_release.freezed.dart';

/// A published release on GitHub Releases.
@freezed
abstract class AppRelease with _$AppRelease {
  const AppRelease._();

  const factory AppRelease({
    /// Without the leading `v`, e.g. `1.2.0`.
    required String version,

    /// Release body in Markdown.
    @Default('') String notes,

    /// Release page on GitHub.
    required String pageUrl,
    @Default([]) List<ReleaseAsset> assets,
  }) = _AppRelease;

  /// Heading that starts the APK table the release workflow appends.
  static const apkTableHeading = '## Which APK?';

  /// [notes] without the APK table, for the update sheet.
  String get changes => notes.split(apkTableHeading).first.trim();

  /// The first asset named `…-<suffix>` for [suffixes] in order, e.g.
  /// `arm64-v8a.apk` then `universal.apk`.
  ReleaseAsset? assetFor(List<String> suffixes) {
    for (final suffix in suffixes) {
      final asset = assets.where((a) => a.name.endsWith('-$suffix'));
      if (asset.isNotEmpty) return asset.first;
    }
    return null;
  }
}

@freezed
abstract class ReleaseAsset with _$ReleaseAsset {
  const factory ReleaseAsset({
    required String name,
    required String url,

    /// Hex SHA-256 from GitHub's asset digest, when available.
    String? sha256,
  }) = _ReleaseAsset;
}
