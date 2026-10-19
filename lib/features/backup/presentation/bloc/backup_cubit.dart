import 'package:bacakomik_app/core/usecase/usecase.dart';
import 'package:bacakomik_app/features/backup/domain/entities/library_backup.dart';
import 'package:bacakomik_app/features/backup/domain/usecases/backup_library.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

part 'backup_cubit.freezed.dart';

@freezed
sealed class BackupState with _$BackupState {
  const factory BackupState.idle() = BackupIdle;
  const factory BackupState.busy() = BackupBusy;
  const factory BackupState.backupSaved() = BackupSaved;
  const factory BackupState.backupFailed() = BackupFailed;
  const factory BackupState.restored() = BackupRestored;
  const factory BackupState.restoreFailed() = BackupRestoreFailed;
}

@injectable
class BackupCubit extends Cubit<BackupState> {
  BackupCubit(this._backupLibrary, this._restoreLibrary)
      : super(const BackupState.idle());

  final BackupLibrary _backupLibrary;
  final RestoreLibrary _restoreLibrary;

  Future<void> backup() async {
    if (state is BackupBusy) return;
    emit(const BackupState.busy());
    final result = await _backupLibrary(const NoParams());
    emit(result.fold(
      (failure) {
        debugPrint('Backup failed: $failure');
        return const BackupState.backupFailed();
      },
      (outcome) => switch (outcome) {
        BackupResult.saved => const BackupState.backupSaved(),
        BackupResult.cancelled ||
        BackupResult.nothingToSave =>
          const BackupState.idle(),
      },
    ));
  }

  Future<void> restore() async {
    if (state is BackupBusy) return;
    emit(const BackupState.busy());
    final result = await _restoreLibrary(const NoParams());
    emit(result.fold(
      (failure) {
        debugPrint('Restore failed: $failure');
        return const BackupState.restoreFailed();
      },
      (outcome) => switch (outcome) {
        RestoreResult.restored => const BackupState.restored(),
        RestoreResult.cancelled => const BackupState.idle(),
      },
    ));
  }
}
