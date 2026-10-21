import 'package:bacakomik_app/core/error/failures.dart';
import 'package:bacakomik_app/features/sync/domain/entities/sync_snapshot.dart';
import 'package:fpdart/fpdart.dart';

/// Google account, the library on this device and its copy in Google Drive.
abstract interface class SyncRepository {
  /// Email of the account signed in on an earlier run, without any prompt.
  /// Null when signed out.
  Future<Either<Failure, String?>> restoreAccount();

  /// Shows the Google sign-in and Drive consent. Returns the email, or null
  /// when the user cancelled.
  Future<Either<Failure, String?>> signIn();

  Future<Either<Failure, Unit>> signOut();

  Future<Either<Failure, SyncSnapshot>> readLocal();

  /// Replaces the synced part of the local library.
  Future<Either<Failure, Unit>> writeLocal(SyncSnapshot snapshot);

  /// Null when nothing was uploaded yet.
  Future<Either<Failure, SyncSnapshot?>> download();

  Future<Either<Failure, Unit>> upload(SyncSnapshot snapshot);

  DateTime? lastSyncedAt();

  /// Null clears it.
  Future<void> saveLastSyncedAt(DateTime? time);
}
