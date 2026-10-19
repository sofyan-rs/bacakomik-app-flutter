/// Progress of downloading and installing an update APK.
sealed class UpdateProgress {
  const UpdateProgress();
}

final class UpdateDownloading extends UpdateProgress {
  const UpdateDownloading(this.percent);

  /// 0–100.
  final int percent;
}

/// The download finished and Android's installer was opened.
final class UpdateInstalling extends UpdateProgress {
  const UpdateInstalling();
}

final class UpdateInstallFailed extends UpdateProgress {
  const UpdateInstallFailed(this.message);

  final String message;
}
