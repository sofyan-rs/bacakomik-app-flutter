import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:bacakomik_app/core/presentation/widgets/dotline/dotline.dart';
import 'package:bacakomik_app/core/theme/dotline_tokens.dart';
import 'package:bacakomik_app/features/sync/presentation/bloc/sync_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons_300.dart';

/// More SYNC group: connect Google Drive, or sync now and disconnect.
class SyncSection extends StatelessWidget {
  const SyncSection({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<SyncCubit>().state;
    final cubit = context.read<SyncCubit>();

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
                  icon: state.status == SyncStatus.failed
                      ? LucideIcons300.cloudAlert
                      : LucideIcons300.cloudSync,
                  title: AppText.syncNow,
                  subtitle: _status(state),
                  onTap: state.busy ? null : cubit.sync,
                ),
                ListRow(
                  icon: LucideIcons300.logOut,
                  title: AppText.syncSignOut,
                  subtitle: state.email,
                  onTap: state.busy ? null : cubit.signOut,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

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
