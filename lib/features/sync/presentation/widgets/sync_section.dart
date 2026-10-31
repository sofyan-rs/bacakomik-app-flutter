import 'dart:io';

import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:bacakomik_app/core/constants/variables.dart';
import 'package:bacakomik_app/core/presentation/widgets/dotline/dotline.dart';
import 'package:bacakomik_app/core/theme/dotline_colors.dart';
import 'package:bacakomik_app/core/theme/dotline_text.dart';
import 'package:bacakomik_app/core/theme/dotline_tokens.dart';
import 'package:bacakomik_app/features/sync/presentation/bloc/sync_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons_300.dart';

/// More SYNC group: connect Google Drive, or the connected account (tap to
/// disconnect) and sync now. Hidden when this build cannot sign in.
class SyncSection extends StatelessWidget {
  const SyncSection({super.key});

  Future<void> _disconnect(BuildContext context, SyncState state) async {
    final confirmed = await showDotSheet<bool>(
      context: context,
      builder: (_) => DisconnectDriveSheet(email: state.email),
    );
    if (confirmed == true && context.mounted) {
      await context.read<SyncCubit>().signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<SyncCubit>().state;
    final cubit = context.read<SyncCubit>();
    if (!state.signedIn && !_canSignIn) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: DotSpace.s3),
        const SectionLabel(label: AppText.sync),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: DotSpace.s4),
          child: ListGroup(
            children: [
              if (!state.signedIn)
                ListRow(
                  icon: LucideIcons300.cloud,
                  title: AppText.syncDrive,
                  subtitle: state.status == SyncStatus.signingIn
                      ? AppText.syncSigningIn
                      : AppText.syncDriveDescription,
                  onTap: state.busy ? null : cubit.signIn,
                )
              else ...[
                ListRow(
                  icon: LucideIcons300.cloud,
                  title: AppText.googleDrive,
                  subtitle: state.email,
                  showChevron: true,
                  onTap: state.busy ? null : () => _disconnect(context, state),
                ),
                ListRow(
                  icon: state.status == SyncStatus.failed
                      ? LucideIcons300.cloudAlert
                      : LucideIcons300.cloudSync,
                  title: AppText.syncNow,
                  subtitle: _status(state),
                  onTap: state.busy ? null : cubit.sync,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// Desktop builds made without a Google desktop client cannot sign in.
  static bool get _canSignIn =>
      Platform.isAndroid ||
      Platform.isIOS ||
      AppVariables.googleDesktopClientId.isNotEmpty;

  static String _status(SyncState state) => switch (state.status) {
    SyncStatus.syncing => AppText.syncing,
    SyncStatus.failed => AppText.syncFailed,
    _ => switch (state.lastSyncedAt) {
      final time? => '${AppText.syncLast} ${formatSyncTime(time)}',
      null => AppText.syncNever,
    },
  };
}

/// `14:05` today, `21/10 14:05` on other days.
String formatSyncTime(DateTime time, {DateTime? now}) {
  final today = now ?? DateTime.now();
  String two(int n) => n.toString().padLeft(2, '0');
  final clock = '${two(time.hour)}:${two(time.minute)}';
  final sameDay =
      time.year == today.year &&
      time.month == today.month &&
      time.day == today.day;
  return sameDay ? clock : '${time.day}/${time.month} $clock';
}

/// Confirms disconnecting Google Drive. Pops `true` to disconnect.
class DisconnectDriveSheet extends StatelessWidget {
  const DisconnectDriveSheet({super.key, this.email});

  final String? email;

  @override
  Widget build(BuildContext context) {
    final c = Dotline.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ActionSheetHeader(
          icon: LucideIcons300.cloud,
          title: AppText.googleDrive,
          subtitle: email,
        ),
        const SizedBox(height: DotSpace.s4),
        Text(
          AppText.syncSignOutDescription,
          style: DotlineText.body.copyWith(color: c.inkMuted),
        ),
        const SizedBox(height: DotSpace.s5),
        DotButton.destructive(
          label: AppText.syncDisconnect,
          onTap: () => Navigator.of(context).pop(true),
        ),
        const SizedBox(height: DotSpace.s3),
        DotButton.outline(
          label: AppText.cancel,
          onTap: () => Navigator.of(context).pop(false),
        ),
      ],
    );
  }
}
