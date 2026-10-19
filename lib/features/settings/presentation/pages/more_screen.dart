import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:bacakomik_app/core/constants/variables.dart';
import 'package:bacakomik_app/core/presentation/widgets/dotline/dotline.dart';
import 'package:bacakomik_app/core/theme/dotline_colors.dart';
import 'package:bacakomik_app/core/theme/dotline_text.dart';
import 'package:bacakomik_app/core/theme/dotline_tokens.dart';
import 'package:bacakomik_app/core/utils/utils.dart';
import 'package:bacakomik_app/features/backup/presentation/bloc/backup_cubit.dart';
import 'package:bacakomik_app/features/bookmark/presentation/bloc/bookmark_cubit.dart';
import 'package:bacakomik_app/features/history/presentation/bloc/history_cubit.dart';
import 'package:bacakomik_app/features/settings/presentation/widgets/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Lainnya tab: library stats, data actions, theme, about.
class MoreScreen extends StatefulWidget {
  const MoreScreen({super.key});

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _appVersion = info.version);
    });
  }

  void _onBackupStateChanged(BuildContext context, BackupState state) {
    if (state is BackupRestored) {
      context.read<BookmarkCubit>().load();
      context.read<HistoryCubit>().load();
    }
    final message = switch (state) {
      BackupSaved() => AppText.successBackupData,
      BackupFailed() => AppText.failedBackupData,
      BackupRestored() => AppText.successRestoreData,
      BackupRestoreFailed() => AppText.failedRestoreData,
      BackupIdle() || BackupBusy() => null,
    };
    if (message != null) showSnackBar(context: context, message: message);
  }

  @override
  Widget build(BuildContext context) {
    final c = Dotline.of(context);
    final bookmarks = context.select<BookmarkCubit, int>((b) => b.state.length);
    final chaptersRead = context.select<HistoryCubit, int>(
      (h) => h.state.length,
    );

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: BlocListener<BackupCubit, BackupState>(
          listener: _onBackupStateChanged,
          child: ListView(
            padding: EdgeInsets.only(
              bottom: DotSpace.s4 + MediaQuery.paddingOf(context).bottom,
            ),
            children: [
              const ScreenHeader(title: AppText.more),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: DotSpace.s4),
                child: Row(
                  children: [
                    Expanded(
                      child: StatTile(
                        value: '$bookmarks',
                        label: AppText.bookmark,
                        labelOnTop: true,
                      ),
                    ),
                    const SizedBox(width: DotSpace.s3),
                    Expanded(
                      child: StatTile(
                        value: '$chaptersRead',
                        label: AppText.chaptersRead,
                        labelOnTop: true,
                      ),
                    ),
                  ],
                ),
              ),
              const Settings(),
              const SizedBox(height: DotSpace.s5),
              Text(
                '${AppVariables.appName} $_appVersion'.toUpperCase(),
                style: DotlineText.label.copyWith(color: c.inkFaint),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
