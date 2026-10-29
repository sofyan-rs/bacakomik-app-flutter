import 'package:bacakomik_app/features/update/domain/entities/app_release.dart';

/// `GET /repos/{owner}/{repo}/releases/latest` from the GitHub API.
class GitHubReleaseModel {
  const GitHubReleaseModel({
    required this.tagName,
    required this.body,
    required this.htmlUrl,
    required this.assets,
  });

  factory GitHubReleaseModel.fromJson(Map<String, dynamic> json) =>
      GitHubReleaseModel(
        tagName: json['tag_name'] as String,
        body: json['body'] as String? ?? '',
        htmlUrl: json['html_url'] as String,
        assets: [
          for (final a in json['assets'] as List? ?? const [])
            GitHubAssetModel.fromJson(a as Map<String, dynamic>),
        ],
      );

  final String tagName;
  final String body;
  final String htmlUrl;
  final List<GitHubAssetModel> assets;

  AppRelease toEntity() => AppRelease(
    version: tagName.replaceFirst(RegExp('^v'), ''),
    notes: body,
    pageUrl: htmlUrl,
    assets: [
      for (final a in assets)
        ReleaseAsset(name: a.name, url: a.downloadUrl, sha256: a.sha256),
    ],
  );
}

class GitHubAssetModel {
  const GitHubAssetModel({
    required this.name,
    required this.downloadUrl,
    this.digest,
  });

  factory GitHubAssetModel.fromJson(Map<String, dynamic> json) =>
      GitHubAssetModel(
        name: json['name'] as String,
        downloadUrl: json['browser_download_url'] as String,
        digest: json['digest'] as String?,
      );

  final String name;
  final String downloadUrl;

  /// `sha256:<hex>`.
  final String? digest;

  String? get sha256 => digest != null && digest!.startsWith('sha256:')
      ? digest!.substring('sha256:'.length)
      : null;
}
