import 'package:bacakomik_app/core/constants/colors.dart';
import 'package:bacakomik_app/core/constants/variables.dart';
import 'package:bacakomik_app/presentation/screens/main/home/widgets/last_read_comic.dart';
import 'package:bacakomik_app/presentation/screens/main/more/widgets/logout_button.dart';
import 'package:bacakomik_app/presentation/screens/main/more/widgets/profile.dart';
import 'package:bacakomik_app/presentation/screens/main/more/widgets/settings.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class MoreScreen extends StatefulWidget {
  const MoreScreen({super.key});

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  String _appVersion = '';

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
    return Scaffold(
      body: SafeArea(
        child: ListView(
          children: [
            ListTile(
              title: const Text(
                AppVariables.appName,
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              subtitle: Text('v$_appVersion'),
            ),
            const Profile(),
            const Padding(
              padding: EdgeInsets.all(15),
              child: LastReadComic(),
            ),
            const Settings(),
            const LogoutButton(),
          ],
        ),
      ),
    );
  }
}
