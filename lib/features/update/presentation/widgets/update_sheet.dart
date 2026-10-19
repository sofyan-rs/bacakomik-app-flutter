import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:bacakomik_app/core/presentation/widgets/dotline/dotline.dart';
import 'package:bacakomik_app/core/theme/dotline_colors.dart';
import 'package:bacakomik_app/core/theme/dotline_text.dart';
import 'package:bacakomik_app/core/theme/dotline_tokens.dart';
import 'package:bacakomik_app/features/update/domain/entities/app_release.dart';
import 'package:bacakomik_app/features/update/presentation/bloc/update_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons_300.dart';
import 'package:url_launcher/url_launcher.dart';

/// Shows [release]'s changes and downloads and installs it.
class UpdateSheet extends StatelessWidget {
  const UpdateSheet({super.key, required this.release});

  final AppRelease release;

  @override
  Widget build(BuildContext context) {
    final c = Dotline.of(context);
    final state = context.watch<UpdateCubit>().state;
    final changes = release.changes;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ActionSheetHeader(
          icon: LucideIcons300.download,
          title: AppText.updateAvailable,
          subtitle: '${AppText.version} ${release.version}',
        ),
        if (changes.isNotEmpty) ...[
          const SizedBox(height: DotSpace.s4),
          Flexible(
            child: SingleChildScrollView(
              child: Text(
                changes,
                style: DotlineText.body.copyWith(color: c.inkMuted),
              ),
            ),
          ),
        ],
        const SizedBox(height: DotSpace.s5),
        ...switch (state) {
          UpdateDownloadingState(:final percent) => [
            Row(
              children: [
                Text(
                  '${AppText.updateDownloading} $percent%'.toUpperCase(),
                  style: DotlineText.label.copyWith(color: c.inkFaint),
                ),
                const Spacer(),
                DotMeter(value: percent, total: 100, dots: 20),
              ],
            ),
          ],
          UpdateInstallFailedState() => [
            Text(
              AppText.updateFailed,
              style: DotlineText.body.copyWith(color: c.accentText),
            ),
            const SizedBox(height: DotSpace.s3),
            DotButton(
              label: AppText.updateRetry,
              onTap: () => context.read<UpdateCubit>().install(),
            ),
          ],
          _ => [
            DotButton(
              label: AppText.updateNow,
              onTap: () => context.read<UpdateCubit>().install(),
            ),
          ],
        },
        const SizedBox(height: DotSpace.s3),
        DotButton.outline(
          label: AppText.viewRelease,
          onTap: () => launchUrl(
            Uri.parse(release.pageUrl),
            mode: LaunchMode.externalApplication,
          ),
        ),
        const SizedBox(height: DotSpace.s3),
        DotButton.outline(
          label: AppText.updateLater,
          onTap: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
