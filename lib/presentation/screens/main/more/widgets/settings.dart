import 'package:bacakomik_app/core/bloc/settings_cubit/settings_cubit.dart';
import 'package:bacakomik_app/core/constants/colors.dart';
import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:bacakomik_app/core/constants/variables.dart';
import 'package:bacakomik_app/core/models/settings_model.dart';
import 'package:bacakomik_app/presentation/screens/main/more/widgets/app_info.dart';
import 'package:bacakomik_app/presentation/screens/sub/history/history_screen.dart';
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
  final Uri _privacyPolicyLink = Uri.parse(AppVariables.privacyPolicyLink);
  final Uri _dmcaLink = Uri.parse(AppVariables.dmcaLink);

  Future<void> _reportBug() async {
    if (!await launchUrl(_reportLink)) {
      throw Exception('Could not launch $_reportLink');
    }
  }

  Future<void> _privacyPolicy() async {
    if (!await launchUrl(_privacyPolicyLink)) {
      throw Exception('Could not launch $_reportLink');
    }
  }

  Future<void> _dmca() async {
    if (!await launchUrl(_dmcaLink)) {
      throw Exception('Could not launch $_reportLink');
    }
  }

  _showAppInfo() {
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
        return SizedBox(
          height: 200,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(context)
                          .colorScheme
                          .onBackground
                          .withOpacity(0.1),
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
                            if (mounted) {
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

  _goToHistoryScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const HistoryScreen(),
      ),
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
        ListTile(
          leading:
              const Icon(SolarIconsOutline.history, color: AppColors.primary),
          title: const Text(AppText.history),
          subtitle: const Text(AppText.historyDescription),
          onTap: _goToHistoryScreen,
        ),
        Container(
          height: 15,
          color: Colors.grey.withOpacity(0.1),
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
          color: Colors.grey.withOpacity(0.1),
        ),
        ListTile(
          leading:
              const Icon(SolarIconsOutline.database, color: AppColors.primary),
          title: const Text(AppText.backupData),
          subtitle: const Text(AppText.backupDataDescription),
          onTap: () {},
        ),
        Divider(
          height: 1,
          color: Colors.grey.withOpacity(0.1),
        ),
        ListTile(
          leading:
              const Icon(SolarIconsOutline.refresh, color: AppColors.primary),
          title: const Text(AppText.restoreData),
          subtitle: const Text(AppText.restoreDataDescription),
          onTap: () {},
        ),
        Container(
          height: 15,
          color: Colors.grey.withOpacity(0.1),
        ),
        ListTile(
          leading: const Icon(SolarIconsOutline.moon, color: AppColors.primary),
          title: const Text(AppText.darkMode),
          subtitle: const Text(AppText.darkModeDescription),
          contentPadding: const EdgeInsets.only(left: 15, top: 0, bottom: 0),
          trailing: BlocBuilder<SettingsCubit, SettingsModel>(
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
          color: Colors.grey.withOpacity(0.1),
        ),
        ListTile(
          leading: const Icon(SolarIconsOutline.bugMinimalistic,
              color: AppColors.primary),
          title: const Text(AppText.bugReport),
          onTap: _reportBug,
        ),
        Divider(
          height: 1,
          color: Colors.grey.withOpacity(0.1),
        ),
        ListTile(
          leading: const Icon(SolarIconsOutline.shieldWarning,
              color: AppColors.primary),
          title: const Text(AppText.privacyPolicy),
          onTap: _privacyPolicy,
        ),
        Divider(
          height: 1,
          color: Colors.grey.withOpacity(0.1),
        ),
        ListTile(
          leading: const Icon(SolarIconsOutline.lockKeyhole,
              color: AppColors.primary),
          title: const Text(AppText.dmca),
          onTap: _dmca,
        ),
        Divider(
          height: 1,
          color: Colors.grey.withOpacity(0.1),
        ),
        ListTile(
          leading: const Icon(SolarIconsOutline.code, color: AppColors.primary),
          title: const Text(AppText.aboutApp),
          onTap: _showAppInfo,
        ),
        Container(
          height: 15,
          color: Colors.grey.withOpacity(0.1),
        ),
      ],
    );
  }
}
