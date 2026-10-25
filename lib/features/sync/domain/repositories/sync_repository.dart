import 'package:bacakomik_app/core/domain/entities/comic_details.dart';
import 'package:bacakomik_app/core/error/failures.dart';
import 'package:bacakomik_app/features/sync/domain/entities/sync_snapshot.dart';
import 'package:fpdart/fpdart.dart';

/// Google account, the library on this device and its copy in Google Drive.
abstract interface class SyncRepository {
  /// Email of the account signed in on an earlier run, without any prompt.
  /// Null when signed out. Fails when an account is stored but could not be
  /// restored now; it stays stored ([storedAccount]).
  Future<Either<Failure, String?>> restoreAccount();

  /// Email of the account last signed in, kept until sign-out; null when
  /// signed out. Nothing is checked with Google.
  String? storedAccount();

  /// Shows the Google sign-in and Drive consent. Returns the email, or null
  /// when the user cancelled.
  Future<Either<Failure, String?>> signIn();

  Future<Either<Failure, Unit>> signOut();

  Future<Either<Failure, SyncSnapshot>> readLocal();

  /// Whether a comic stored on this device, as a bookmark or in the
  /// history, passes [test] with its key and details. Only the records
  /// whose key passes [where] are read, so a check that rules most keys out
  /// by key alone does not decode the library.
  Future<Either<Failure, bool>> anyLocalComic({
    required bool Function(String key) where,
    required bool Function(String key, ComicDetails details) test,
  });

  /// Replaces the synced part of the local library, as changed since the
  /// last [readLocal]: records saved or deleted after that read are kept.
  Future<Either<Failure, Unit>> writeLocal(SyncSnapshot snapshot);

  /// Null when nothing was uploaded yet.
  Future<Either<Failure, SyncSnapshot?>> download();

  Future<Either<Failure, Unit>> upload(SyncSnapshot snapshot);

  DateTime? lastSyncedAt();

  /// Null clears it.
  Future<void> saveLastSyncedAt(DateTime? time);
}
