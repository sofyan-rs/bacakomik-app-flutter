import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:bacakomik_app/core/constants/variables.dart';
import 'package:bacakomik_app/core/presentation/widgets/dotline/dotline.dart';
import 'package:bacakomik_app/core/theme/dotline_tokens.dart';
import 'package:bacakomik_app/core/utils/utils.dart';
import 'package:bacakomik_app/features/backup/presentation/bloc/backup_cubit.dart';
import 'package:bacakomik_app/features/download/presentation/bloc/download_cubit.dart';
import 'package:bacakomik_app/features/download/presentation/pages/downloads_screen.dart';
import 'package:bacakomik_app/features/source/presentation/bloc/sources_cubit.dart';
import 'package:bacakomik_app/features/source/presentation/pages/extensions_screen.dart';
import 'package:bacakomik_app/features/settings/domain/entities/app_settings.dart';
import 'package:bacakomik_app/features/settings/presentation/bloc/settings_cubit.dart';
import 'package:bacakomik_app/features/settings/presentation/widgets/app_info.dart';
import 'package:bacakomik_app/features/settings/presentation/widgets/clear_cache_sheet.dart';
import 'package:bacakomik_app/features/sync/presentation/widgets/sync_section.dart';
import 'package:bacakomik_app/features/update/presentation/bloc/update_cubit.dart';
import 'package:bacakomik_app/features/migration/presentation/pages/migration_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons_300.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:bacakomik_app/features/category/presentation/pages/categories_screen.dart';
import 'package:bacakomik_app/core/network/image_cache.dart';

/// More groups: incognito mode, SOURCES, LIBRARY (categories, downloads,
/// cache), BACKUP & SYNC, THEME, ABOUT.
class Settings extends StatelessWidget {
  const Settings({super.key});

  Future<void> _clearCache(BuildContext context) async {
    final confirmed = await showDotSheet<bool>(
      context: context,
      builder: (_) => const ClearCacheSheet(),
    );
    if (confirmed != true) return;
    await comicImageCache.emptyCache();
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
    final checkingUpdate = context.select<UpdateCubit, bool>(
      (u) => u.state is UpdateChecking,
    );
    final themeMode = context.select<SettingsCubit, AppThemeMode>(
      (s) => s.state.themeMode,
    );
    final downloadedBytes = context.select<DownloadCubit, int>(
      (d) => d.state.totalBytes,
    );
    final extensionUpdates = context.select<SourcesCubit, int>(
      (s) => s.state.updateCount,
    );
    final incognito = context.select<SettingsCubit, bool>(
      (s) => s.state.incognito,
    );
    void setIncognito(bool on) =>
        context.read<SettingsCubit>().update((s) => s.copyWith(incognito: on));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: DotSpace.s5),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: DotSpace.s4),
          child: ListGroup(
            children: [
              ListRow(
                icon: LucideIcons300.hatGlasses,
                title: AppText.incognito,
                subtitle: AppText.incognitoDescription,
                trailing: DotSwitch(
                  value: incognito,
                  semanticLabel: AppText.incognito,
                  onChanged: setIncognito,
                ),
                onTap: () => setIncognito(!incognito),
              ),
            ],
          ),
        ),
        const SizedBox(height: DotSpace.s3),
        const SectionLabel(label: AppText.sources),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: DotSpace.s4),
          child: ListGroup(
            children: [
              ListRow(
                icon: LucideIcons300.puzzle,
                title: AppText.extensions,
                subtitle: AppText.extensionsDescription,
                trailing: extensionUpdates == 0
                    ? null
                    : UpdateBadge(count: extensionUpdates),
                showChevron: true,
                onTap: () => ExtensionsScreen.open(context),
              ),
            ],
          ),
        ),
        const SizedBox(height: DotSpace.s3),
        const SectionLabel(label: AppText.library),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: DotSpace.s4),
          child: ListGroup(
            children: [
              ListRow(
                icon: LucideIcons300.folder,
                title: AppText.categories,
                subtitle: AppText.groupByCategoryDescription,
                showChevron: true,
                onTap: () => CategoriesScreen.open(context),
              ),
              ListRow(
                icon: LucideIcons300.download,
                title: AppText.downloads,
                subtitle: AppText.downloadsDescription,
                value: downloadedBytes == 0
                    ? null
                    : formatBytes(downloadedBytes),
                showChevron: true,
                onTap: () => DownloadsScreen.open(context),
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
        SyncSection(
          backup: [
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
              onTap: busy ? null : () => context.read<BackupCubit>().restore(),
            ),
            ListRow(
              icon: LucideIcons300.arrowRightLeft,
              title: AppText.migration,
              subtitle: AppText.migrationDescription,
              showChevron: true,
              onTap: () => MigrationScreen.open(context),
            ),
          ],
        ),
        const SizedBox(height: DotSpace.s3),
        const SectionLabel(label: AppText.theme),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: DotSpace.s4),
          child: SegmentedControl<AppThemeMode>(
            selected: themeMode,
            onChanged: (mode) =>
                context.read<SettingsCubit>().changeThemeMode(mode),
            segments: const [
              Segment(value: AppThemeMode.system, label: AppText.themeSystem),
              Segment(value: AppThemeMode.light, label: AppText.themeLight),
              Segment(value: AppThemeMode.dark, label: AppText.themeDark),
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
                icon: LucideIcons300.refreshCw,
                title: AppText.checkUpdate,
                onTap: checkingUpdate
                    ? null
                    : () => context.read<UpdateCubit>().check(),
              ),
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
