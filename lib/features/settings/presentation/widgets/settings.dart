import 'package:bacakomik_app/features/settings/presentation/bloc/settings_cubit.dart';
import 'package:bacakomik_app/core/constants/colors.dart';
import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:bacakomik_app/core/constants/variables.dart';
import 'package:bacakomik_app/features/settings/domain/entities/app_settings.dart';
import 'package:bacakomik_app/features/backup/presentation/bloc/backup_cubit.dart';
import 'package:bacakomik_app/features/settings/presentation/widgets/app_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:solar_icons/solar_icons.dart';
import 'package:url_launcher/url_launcher.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  final DefaultCacheManager _cacheManager = DefaultCacheManager();

  final Uri _reportLink = Uri.parse(AppVariables.reportLink);

  Future<void> _reportBug() async {
    if (!await launchUrl(_reportLink)) {
      throw Exception('Could not launch $_reportLink');
    }
  }

  void _showAppInfo() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            AppText.aboutApp,
            style: TextStyle(fontSize: 18),
          ),
          content: const AppInfo(),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                'Tutup',
                style: TextStyle(
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _clearCache() {
    showModalBottomSheet(
      useSafeArea: true,
      isScrollControlled: true,
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                ),
                child: const Text(
                  AppText.clearCache,
                  style: TextStyle(fontSize: 18),
                  textAlign: TextAlign.center,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      AppText.clearCacheConfirmation,
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text(
                            AppText.cancel,
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: () async {
                            await _cacheManager.emptyCache();
                            if (context.mounted) {
                              Navigator.of(context).pop();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text(
                            AppText.delete,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Divider(
          height: 1,
          color: Colors.grey.withValues(alpha: 0.1),
        ),
        ListTile(
          leading: const Icon(SolarIconsOutline.trashBinMinimalistic,
              color: AppColors.primary),
          title: const Text(AppText.clearCache),
          subtitle: const Text(AppText.clearCacheDescription),
          onTap: _clearCache,
        ),
        Divider(
          height: 1,
          color: Colors.grey.withValues(alpha: 0.1),
        ),
        ListTile(
          leading:
              const Icon(SolarIconsOutline.database, color: AppColors.primary),
          title: const Text(AppText.backupData),
          subtitle: const Text(AppText.backupDataDescription),
          onTap: () async {
            await context.read<BackupCubit>().backup();
          },
        ),
        Divider(
          height: 1,
          color: Colors.grey.withValues(alpha: 0.1),
        ),
        ListTile(
          leading:
              const Icon(SolarIconsOutline.refresh, color: AppColors.primary),
          title: const Text(AppText.restoreData),
          subtitle: const Text(AppText.restoreDataDescription),
          onTap: () async {
            await context.read<BackupCubit>().restore();
          },
        ),
        Container(
          height: 15,
          color: Colors.grey.withValues(alpha: 0.1),
        ),
        ListTile(
          leading: const Icon(SolarIconsOutline.moon, color: AppColors.primary),
          title: const Text(AppText.darkMode),
          subtitle: const Text(AppText.darkModeDescription),
          contentPadding: const EdgeInsets.only(left: 15, top: 0, bottom: 0),
          trailing: BlocBuilder<SettingsCubit, AppSettings>(
            builder: (context, state) {
              return DropdownButton(
                borderRadius: BorderRadius.circular(5),
                underline: Container(),
                icon: const Icon(
                  SolarIconsBold.altArrowDown,
                  size: 16,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 15),
                value: state.darkMode,
                items: const [
                  DropdownMenuItem(
                    value: AppText.system,
                    child: Text(AppText.system),
                  ),
                  DropdownMenuItem(
                    value: AppText.dark,
                    child: Text(AppText.dark),
                  ),
                  DropdownMenuItem(
                    value: AppText.light,
                    child: Text(AppText.light),
                  ),
                ],
                onChanged: (value) {
                  context
                      .read<SettingsCubit>()
                      .changeDarkMode(value.toString());
                },
              );
            },
          ),
        ),
        Container(
          height: 15,
          color: Colors.grey.withValues(alpha: 0.1),
        ),
        ListTile(
          leading: const Icon(SolarIconsOutline.bugMinimalistic,
              color: AppColors.primary),
          title: const Text(AppText.bugReport),
          onTap: _reportBug,
        ),
        Divider(
          height: 1,
          color: Colors.grey.withValues(alpha: 0.1),
        ),
        ListTile(
          leading: const Icon(SolarIconsOutline.code, color: AppColors.primary),
          title: const Text(AppText.aboutApp),
          onTap: _showAppInfo,
        ),
      ],
    );
  }
}
