import 'package:bacakomik_app/core/error/failures.dart';
import 'package:bacakomik_app/core/usecase/usecase.dart';
import 'package:bacakomik_app/core/utils/clock.dart';
import 'package:bacakomik_app/features/sync/domain/entities/sync_snapshot.dart';
import 'package:bacakomik_app/features/sync/domain/repositories/sync_repository.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

/// Signed-in account and the last successful sync.
typedef SyncAccount = ({String? email, DateTime? lastSyncedAt});

/// Outcome of one sync.
typedef SyncResult = ({DateTime syncedAt, bool localChanged});

/// Restores the account signed in on an earlier run, without any prompt.
@injectable
class RestoreSyncAccount implements UseCase<SyncAccount, NoParams> {
  const RestoreSyncAccount(this._repository);

  final SyncRepository _repository;

  @override
  Future<Either<Failure, SyncAccount>> call(NoParams params) async {
    final email = await _repository.restoreAccount();
    return email.map(
      (email) => (
        email: email,
        lastSyncedAt: email == null ? null : _repository.lastSyncedAt(),
      ),
    );
  }
}

/// Returns the email, or null when the user cancelled.
@injectable
class SignInSync implements UseCase<String?, NoParams> {
  const SignInSync(this._repository);

  final SyncRepository _repository;

  @override
  Future<Either<Failure, String?>> call(NoParams params) =>
      _repository.signIn();
}

/// Signs out and forgets the last sync. The local library is kept.
@injectable
class SignOutSync implements UseCase<Unit, NoParams> {
  const SignOutSync(this._repository);

  final SyncRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(NoParams params) async {
    final result = await _repository.signOut();
    if (result.isRight()) await _repository.saveLastSyncedAt(null);
    return result;
  }
}

/// Merges the local library with its Drive copy, saves the result on this
/// device, then uploads it when the Drive copy differs.
@injectable
class SyncLibrary implements UseCase<SyncResult, NoParams> {
  const SyncLibrary(this._repository, this._clock);

  /// Deletions are synced for this long; a device offline for longer may
  /// bring deleted entries back.
  static const keepDeletionsFor = Duration(days: 180);

  final SyncRepository _repository;
  final Clock _clock;

  @override
  Future<Either<Failure, SyncResult>> call(NoParams params) async {
    final now = _clock.now();
    final keepSince = now.subtract(keepDeletionsFor);
    SyncSnapshot merge(SyncSnapshot a, SyncSnapshot b) =>
        SyncSnapshot.merge(a, b, keepDeletionsSince: keepSince);

    final remoteResult = await _repository.download();
    final localResult = await _repository.readLocal();
    return remoteResult.flatMap((r) => localResult.map((l) => (r, l))).fold(
      (failure) async => left(failure),
      (data) async {
        final (remote, local) = data;
        var merged = merge(local, remote ?? const SyncSnapshot());

        // Re-read so edits made while downloading are kept.
        final latest = await _repository.readLocal();
        if (latest case Right(value: final current)) {
          merged = merge(merged, current);
        }
        final localChanged = !merged.sameAs(local);
        if (localChanged) {
          final written = await _repository.writeLocal(merged);
          if (written case Left(value: final failure)) return left(failure);
        }

        if (remote == null || !merged.sameAs(remote)) {
          final uploaded = await _repository.upload(merged);
          if (uploaded case Left(value: final failure)) return left(failure);
        }

        await _repository.saveLastSyncedAt(now);
        return right((syncedAt: now, localChanged: localChanged));
      },
    );
  }
}
