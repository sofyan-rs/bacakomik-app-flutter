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
    @Default([]) List<ReleaseApk> apks,
  }) = _AppRelease;

  /// Heading that starts the APK table the release workflow appends.
  static const apkTableHeading = '## Which APK?';

  /// [notes] without the APK table, for the update sheet.
  String get changes => notes.split(apkTableHeading).first.trim();

  /// The APK built for [abi] (e.g. `arm64-v8a`), else the universal APK.
  ReleaseApk? apkFor(String? abi) {
    ReleaseApk? withSuffix(String suffix) =>
        apks.where((a) => a.name.endsWith('-$suffix.apk')).firstOrNull;
    return (abi == null ? null : withSuffix(abi)) ?? withSuffix('universal');
  }
}

@freezed
abstract class ReleaseApk with _$ReleaseApk {
  const factory ReleaseApk({
    required String name,
    required String url,

    /// Hex SHA-256 from GitHub's asset digest, when available.
    String? sha256,
  }) = _ReleaseApk;
}
