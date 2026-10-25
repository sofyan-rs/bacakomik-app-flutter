import 'dart:async';

import 'package:bacakomik_app/core/error/failures.dart';
import 'package:bacakomik_app/core/storage/library_journal.dart';
import 'package:bacakomik_app/core/usecase/usecase.dart';
import 'package:bacakomik_app/features/sync/domain/usecases/migrate_library.dart';
import 'package:bacakomik_app/features/sync/domain/usecases/sync_usecases.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

part 'sync_cubit.freezed.dart';

enum SyncStatus { idle, signingIn, signInFailed, syncing, failed }

@freezed
abstract class SyncState with _$SyncState {
  const SyncState._();

  const factory SyncState({
    /// Signed-in Google account; null when sync is off.
    String? email,
    DateTime? lastSyncedAt,
    @Default(SyncStatus.idle) SyncStatus status,

    /// Incremented each time sync changed the local library, so library
    /// cubits know to reload.
    @Default(0) int libraryRevision,
  }) = _SyncState;

  bool get signedIn => email != null;

  bool get busy =>
      status == SyncStatus.signingIn || status == SyncStatus.syncing;
}

/// Google Drive sync of bookmarks and history. Once signed in, syncs on
/// start, when the app returns to the foreground, and shortly after each
/// library edit. Signed out, it still migrates the library to the API's
/// current source on start and on resume (sync does that when signed in).
@injectable
class SyncCubit extends Cubit<SyncState> {
  SyncCubit(
    this._restoreAccount,
    this._signIn,
    this._signOut,
    this._syncLibrary,
    this._migrateLocal,
    this._journal,
  ) : super(const SyncState());

  final RestoreSyncAccount _restoreAccount;
  final SignInSync _signIn;
  final SignOutSync _signOut;
  final SyncLibrary _syncLibrary;
  final MigrateLocalLibrary _migrateLocal;
  final LibraryJournal _journal;

  /// Wait after an edit, so a burst of edits uploads once.
  static const editDelay = Duration(seconds: 5);

  /// Coming back to the app syncs only when the last sync is older.
  static const resumeInterval = Duration(minutes: 1);

  StreamSubscription<void>? _edits;
  AppLifecycleListener? _lifecycle;
  Timer? _debounce;
  bool _syncAgain = false;
  bool _migrating = false;

  /// The signed-in account is restored with Google for this run. A stored
  /// account that could not be restored at start (offline, a platform
  /// error) stays signed in, shown as failed; the next sync (on resume, or
  /// tapped) tries to restore it first.
  bool _restored = false;

  Future<void> start() async {
    _edits = _journal.changes.listen((_) => _scheduleSync());
    _lifecycle = AppLifecycleListener(onResume: _onResume);

    try {
      final account = await _restoreAccount(const NoParams());
      account.fold(_log, _setAccount);
    } catch (e) {
      _log(ServerFailure('$e'));
    }
    if (isClosed) return;
    if (state.signedIn && !_restored) {
      emit(state.copyWith(status: SyncStatus.failed));
    } else if (state.signedIn) {
      await sync();
    } else {
      await _migrate();
    }
  }

  void _setAccount(SyncAccount account) {
    if (isClosed) return;
    _restored = account.restored;
    emit(
      state.copyWith(email: account.email, lastSyncedAt: account.lastSyncedAt),
    );
  }

  Future<void> signIn() async {
    if (state.busy) return;
    emit(state.copyWith(status: SyncStatus.signingIn));
    final result = await _signIn(const NoParams());
    result.fold(
      (failure) {
        _log(failure);
        emit(state.copyWith(status: SyncStatus.signInFailed));
      },
      (email) {
        _restored = email != null;
        emit(state.copyWith(email: email, status: SyncStatus.idle));
      },
    );
    if (state.signedIn) await sync();
  }

  Future<void> signOut() async {
    _debounce?.cancel();
    final result = await _signOut(const NoParams());
    result.fold(_log, (_) {
      _restored = false;
      emit(
        state.copyWith(
          email: null,
          lastSyncedAt: null,
          status: SyncStatus.idle,
        ),
      );
    });
  }

  /// Runs one sync, or queues another one after the running sync.
  Future<void> sync() async {
    if (!state.signedIn || isClosed) return;
    _debounce?.cancel();
    if (state.status == SyncStatus.syncing) {
      _syncAgain = true;
      return;
    }

    emit(state.copyWith(status: SyncStatus.syncing));
    // Whatever happens below, the status leaves `syncing`.
    var status = SyncStatus.failed;
    var signedOut = false;
    try {
      if (!_restored) {
        final account = await _restoreAccount(const NoParams());
        account.fold(_log, _setAccount);
        if (!_restored || isClosed) return;
      }
      final result = await _syncLibrary(const NoParams());
      if (isClosed) return;
      result.fold(
        (failure) {
          _log(failure);
          // Access was revoked: show the signed-out state.
          signedOut = failure is AuthFailure;
        },
        (result) {
          status = SyncStatus.idle;
          emit(
            state.copyWith(
              lastSyncedAt: result.syncedAt,
              libraryRevision: result.localChanged
                  ? state.libraryRevision + 1
                  : state.libraryRevision,
            ),
          );
        },
      );
    } catch (e) {
      _log(ServerFailure('$e'));
    } finally {
      if (!isClosed) {
        if (signedOut) _restored = false;
        emit(
          state.copyWith(status: status, email: signedOut ? null : state.email),
        );
      }
    }

    if (_syncAgain && !isClosed) {
      _syncAgain = false;
      await sync();
    }
  }

  void _scheduleSync() {
    if (!state.signedIn) return;
    _debounce?.cancel();
    _debounce = Timer(editDelay, sync);
  }

  /// Library migration while signed out.
  Future<void> _migrate() async {
    if (_migrating || state.signedIn || isClosed) return;
    _migrating = true;
    final result = await _migrateLocal(const NoParams());
    _migrating = false;
    if (isClosed) return;
    result.fold(_log, (changed) {
      if (changed) {
        emit(state.copyWith(libraryRevision: state.libraryRevision + 1));
      }
    });
  }

  void _onResume() {
    if (!state.signedIn) {
      _migrate();
      return;
    }
    final last = state.lastSyncedAt;
    if (!_restored ||
        last == null ||
        DateTime.now().difference(last) > resumeInterval) {
      sync();
    }
  }

  void _log(Failure failure) => debugPrint('SyncCubit: $failure');

  @override
  Future<void> close() {
    _debounce?.cancel();
    _edits?.cancel();
    _lifecycle?.dispose();
    return super.close();
  }
}
