import 'package:bacakomik_app/core/bloc/settings_cubit/settings_cubit.dart';
import 'package:bacakomik_app/core/constants/colors.dart';
import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:bacakomik_app/core/constants/variables.dart';
import 'package:bacakomik_app/core/models/settings_model.dart';
import 'package:bacakomik_app/presentation/screens/main/more/widgets/app_info.dart';
import 'package:bacakomik_app/presentation/screens/sub/history/history_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_icons/solar_icons.dart';
import 'package:url_launcher/url_launcher.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  final Uri _reportLink = Uri.parse(AppVariables.reportLink);

  Future<void> _reportBug() async {
    if (!await launchUrl(_reportLink)) {
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
          onTap: () {},
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
