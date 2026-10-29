import 'package:bacakomik_app/core/error/failures.dart';
import 'package:bacakomik_app/features/update/domain/entities/app_release.dart';
import 'package:bacakomik_app/features/update/domain/entities/update_progress.dart';
import 'package:fpdart/fpdart.dart';

abstract interface class UpdateRepository {
  /// Newest published release, excluding drafts and pre-releases.
  Future<Either<Failure, AppRelease>> latestRelease();

  /// Version name of the installed app, e.g. `1.0.0`.
  Future<String> installedVersion();

  /// Endings of the release assets that install on this device, best
  /// first (see [AppRelease.assetFor]).
  Future<List<String>> assetSuffixes();

  /// Downloads [asset] and installs it.
  Stream<UpdateProgress> install(ReleaseAsset asset);
}
