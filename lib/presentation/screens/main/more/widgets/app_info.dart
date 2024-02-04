import 'package:bacakomik_app/core/constants/changelogs.dart';
import 'package:bacakomik_app/core/constants/colors.dart';
import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:bacakomik_app/core/constants/variables.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppInfo extends StatefulWidget {
  const AppInfo({super.key});

  @override
  State<AppInfo> createState() => _AppInfoState();
}

class _AppInfoState extends State<AppInfo> {
  String _appVersion = '';
  final _appChangelogs = AppChangelogs.changelogs;

  getAppVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = packageInfo.version;
    });
  }

  @override
  void initState() {
    super.initState();
    getAppVersion();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            AppVariables.appName,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          Text('${AppText.version} $_appVersion'),
          const SizedBox(height: 10),
          const Text(AppVariables.appDescription),
          const Divider(
            color: AppColors.primary,
            thickness: 1,
            height: 30,
          ),
          const Text(
            'Changelog :',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          for (var changelog in _appChangelogs.reversed)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  changelog['version'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                for (var change in changelog['changes']) Text(' - $change'),
                const SizedBox(height: 10),
              ],
            ),
        ],
      ),
    );
  }
}
