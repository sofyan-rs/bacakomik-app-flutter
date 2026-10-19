import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:bacakomik_app/core/constants/variables.dart';
import 'package:bacakomik_app/core/presentation/widgets/dotline/dotline.dart';
import 'package:bacakomik_app/core/theme/dotline_colors.dart';
import 'package:bacakomik_app/core/theme/dotline_text.dart';
import 'package:bacakomik_app/core/theme/dotline_tokens.dart';
import 'package:bacakomik_app/core/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons_300.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// "Tentang aplikasi" sheet: version, description and a link to the
/// developer site.
class AppInfo extends StatefulWidget {
  const AppInfo({super.key});

  @override
  State<AppInfo> createState() => _AppInfoState();
}

class _AppInfoState extends State<AppInfo> {
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _appVersion = info.version);
    });
  }

  Future<void> _openWebsite() async {
    final opened = await launchUrl(
      Uri.parse(AppVariables.websiteLink),
      mode: LaunchMode.externalApplication,
    );
    if (!opened && mounted) {
      showSnackBar(context: context, message: AppText.linkFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = Dotline.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ActionSheetHeader(
          icon: LucideIcons300.info,
          title: AppVariables.appName,
          subtitle: '${AppText.version} $_appVersion',
        ),
        const SizedBox(height: DotSpace.s4),
        Text(
          AppVariables.appDescription,
          style: DotlineText.body.copyWith(color: c.inkMuted),
        ),
        const SizedBox(height: DotSpace.s5),
        ListGroup(
          background: c.bg,
          children: [
            ListRow(
              icon: LucideIcons300.globe,
              title: AppText.website,
              subtitle: AppVariables.websiteLabel,
              onTap: _openWebsite,
            ),
          ],
        ),
      ],
    );
  }
}
