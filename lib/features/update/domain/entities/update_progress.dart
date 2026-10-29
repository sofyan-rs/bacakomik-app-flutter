/// Progress of downloading and installing an update.
sealed class UpdateProgress {
  const UpdateProgress();
}

final class UpdateDownloading extends UpdateProgress {
  const UpdateDownloading(this.percent);

  /// 0–100.
  final int percent;
}

/// The download finished and the installer took over: Android's, or on
/// desktop a script that replaces the app once it quits.
final class UpdateInstalling extends UpdateProgress {
  const UpdateInstalling();
}

final class UpdateInstallFailed extends UpdateProgress {
  const UpdateInstallFailed(this.message);

  final String message;
}
