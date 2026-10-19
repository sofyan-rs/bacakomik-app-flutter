import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:bacakomik_app/core/constants/variables.dart';
import 'package:bacakomik_app/core/presentation/widgets/dotline/dotline.dart';
import 'package:bacakomik_app/core/theme/dotline_tokens.dart';
import 'package:bacakomik_app/core/utils/utils.dart';
import 'package:bacakomik_app/features/backup/presentation/bloc/backup_cubit.dart';
import 'package:bacakomik_app/features/settings/presentation/bloc/settings_cubit.dart';
import 'package:bacakomik_app/features/settings/presentation/widgets/app_info.dart';
import 'package:bacakomik_app/features/settings/presentation/widgets/clear_cache_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:lucide_icons_flutter/lucide_icons_300.dart';
import 'package:url_launcher/url_launcher.dart';

/// Lainnya groups: DATA, TEMA, TENTANG.
class Settings extends StatelessWidget {
  const Settings({super.key});

  Future<void> _clearCache(BuildContext context) async {
    final confirmed = await showDotSheet<bool>(
      context: context,
      builder: (_) => const ClearCacheSheet(),
    );
    if (confirmed != true) return;
    await DefaultCacheManager().emptyCache();
    if (context.mounted) {
      showSnackBar(context: context, message: AppText.cacheCleared);
    }
  }

  Future<void> _reportBug(BuildContext context) async {
    final opened = await launchUrl(
      Uri.parse(AppVariables.reportLink),
      mode: LaunchMode.externalApplication,
    );
    if (!opened && context.mounted) {
      showSnackBar(context: context, message: AppText.linkFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = context.watch<BackupCubit>().state is BackupBusy;
    final darkMode = context.select<SettingsCubit, String>(
      (s) => s.state.darkMode,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: DotSpace.s3),
        const SectionLabel(label: AppText.data),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: DotSpace.s4),
          child: ListGroup(
            children: [
              ListRow(
                icon: LucideIcons300.database,
                title: AppText.backupData,
                subtitle: AppText.backupDataDescription,
                onTap: busy ? null : () => context.read<BackupCubit>().backup(),
              ),
              ListRow(
                icon: LucideIcons300.rotateCcw,
                title: AppText.restoreData,
                subtitle: AppText.restoreDataDescription,
                onTap: busy
                    ? null
                    : () => context.read<BackupCubit>().restore(),
              ),
              ListRow(
                icon: LucideIcons300.trash2,
                title: AppText.clearCache,
                subtitle: AppText.clearCacheDescription,
                onTap: () => _clearCache(context),
              ),
            ],
          ),
        ),
        const SizedBox(height: DotSpace.s3),
        const SectionLabel(label: AppText.theme),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: DotSpace.s4),
          child: SegmentedControl<String>(
            selected: darkMode,
            onChanged: (mode) =>
                context.read<SettingsCubit>().changeDarkMode(mode),
            // Stored values stay the old dropdown labels (AppSettings).
            segments: const [
              Segment(value: AppText.system, label: AppText.themeSystem),
              Segment(value: AppText.light, label: AppText.themeLight),
              Segment(value: AppText.dark, label: AppText.themeDark),
            ],
          ),
        ),
        const SizedBox(height: DotSpace.s3),
        const SectionLabel(label: AppText.about),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: DotSpace.s4),
          child: ListGroup(
            children: [
              ListRow(
                icon: LucideIcons300.bug,
                title: AppText.bugReport,
                onTap: () => _reportBug(context),
              ),
              ListRow(
                icon: LucideIcons300.info,
                title: AppText.aboutApp,
                onTap: () => showDotSheet<void>(
                  context: context,
                  builder: (_) => const AppInfo(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
