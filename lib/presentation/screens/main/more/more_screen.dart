import 'package:bacakomik_app/core/constants/colors.dart';
import 'package:bacakomik_app/core/constants/variables.dart';
import 'package:bacakomik_app/presentation/screens/main/home/widgets/last_read_comic.dart';
import 'package:bacakomik_app/presentation/screens/main/more/widgets/logout_button.dart';
import 'package:bacakomik_app/presentation/screens/main/more/widgets/settings.dart';
import 'package:flutter/material.dart';

class MoreScreen extends StatefulWidget {
  const MoreScreen({super.key});

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          children: const [
            ListTile(
              title: Text(
                AppVariables.appName,
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              subtitle: Text('v${AppVariables.appVersion}'),
            ),
            Padding(
              padding: EdgeInsets.all(15),
              child: LastReadComic(),
            ),
            Settings(),
            LogoutButton(),
          ],
        ),
      ),
    );
  }
}
