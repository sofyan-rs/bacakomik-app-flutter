import 'package:bacakomik_app/core/constants/colors.dart';
import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:bacakomik_app/core/constants/variables.dart';
import 'package:bacakomik_app/core/utils/utils.dart';
import 'package:bacakomik_app/features/backup/presentation/bloc/backup_cubit.dart';
import 'package:bacakomik_app/features/bookmark/presentation/bloc/bookmark_cubit.dart';
import 'package:bacakomik_app/features/history/presentation/bloc/history_cubit.dart';
import 'package:bacakomik_app/features/home/presentation/widgets/last_read_comic.dart';
import 'package:bacakomik_app/features/settings/presentation/widgets/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';

class MoreScreen extends StatefulWidget {
  const MoreScreen({super.key});

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  String _appVersion = '';

  Future<void> getAppVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = packageInfo.version;
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
            const LastReadComic(),
            BlocListener<BackupCubit, BackupState>(
              listener: _onBackupStateChanged,
              child: const Settings(),
            ),
          ],
        ),
      ),
    );
  }
}
