import 'dart:async';

import 'package:bacakomik_app/core/usecase/usecase.dart';
import 'package:bacakomik_app/features/update/domain/entities/app_release.dart';
import 'package:bacakomik_app/features/update/domain/entities/update_progress.dart';
import 'package:bacakomik_app/features/update/domain/usecases/update_usecases.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

part 'update_cubit.freezed.dart';

@freezed
sealed class UpdateState with _$UpdateState {
  const factory UpdateState.idle() = UpdateIdle;
  const factory UpdateState.checking() = UpdateChecking;
  const factory UpdateState.upToDate() = UpdateUpToDate;
  const factory UpdateState.checkFailed() = UpdateCheckFailed;
  const factory UpdateState.available(AppRelease release) = UpdateAvailable;
  const factory UpdateState.downloading(AppRelease release, int percent) =
      UpdateDownloadingState;
  const factory UpdateState.installFailed(AppRelease release) =
      UpdateInstallFailedState;
}

@injectable
class UpdateCubit extends Cubit<UpdateState> {
  UpdateCubit(this._checkForUpdate, this._installUpdate)
    : super(const UpdateState.idle());

  final CheckForUpdate _checkForUpdate;
  final InstallUpdate _installUpdate;
  StreamSubscription<UpdateProgress>? _install;

  /// [quiet] (the check on app start) ends in idle instead of reporting
  /// "up to date" or a failure.
  Future<void> check({bool quiet = false}) async {
    if (state is UpdateChecking || state is UpdateDownloadingState) return;
    emit(const UpdateState.checking());
    final result = await _checkForUpdate(const NoParams());
    emit(
      result.fold(
        (failure) {
          debugPrint('UpdateCubit: $failure');
          return quiet
              ? const UpdateState.idle()
              : const UpdateState.checkFailed();
        },
        (release) => release != null
            ? UpdateState.available(release)
            : quiet
            ? const UpdateState.idle()
            : const UpdateState.upToDate(),
      ),
    );
  }

  void install() {
    final release = switch (state) {
      UpdateAvailable(:final release) => release,
      UpdateInstallFailedState(:final release) => release,
      _ => null,
    };
    if (release == null) return;
    emit(UpdateState.downloading(release, 0));
    _install = _installUpdate(release).listen(
      (progress) => emit(switch (progress) {
        UpdateDownloading(:final percent) => UpdateState.downloading(
          release,
          percent,
        ),
        // Android's installer takes over; back to the button in case the
        // user cancels it.
        UpdateInstalling() => UpdateState.available(release),
        UpdateInstallFailed(:final message) => () {
          debugPrint('UpdateCubit: $message');
          return UpdateState.installFailed(release);
        }(),
      }),
      onDone: () {
        if (state is UpdateDownloadingState) {
          emit(UpdateState.available(release));
        }
      },
    );
  }

  @override
  Future<void> close() async {
    await _install?.cancel();
    return super.close();
  }
}
