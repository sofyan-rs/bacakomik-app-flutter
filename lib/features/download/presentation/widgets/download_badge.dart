import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:bacakomik_app/core/theme/dotline_colors.dart';
import 'package:bacakomik_app/core/theme/dotline_text.dart';
import 'package:bacakomik_app/core/theme/dotline_tokens.dart';
import 'package:bacakomik_app/features/download/domain/entities/downloaded_chapter.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons_300.dart';

/// Download state of a chapter: saved, queued, page progress (`12/30`) or
/// failed.
class DownloadBadge extends StatelessWidget {
  const DownloadBadge({super.key, required this.download});

  final DownloadedChapter download;

  @override
  Widget build(BuildContext context) {
    final c = Dotline.of(context);
    Widget icon(IconData icon, Color color, String label) => Semantics(
      label: label,
      child: Icon(icon, size: DotSize.iconSmall, color: color),
    );

    return switch (download.status) {
      DownloadStatus.completed => icon(
        LucideIcons300.arrowDownToLine,
        c.inkFaint,
        AppText.downloadedLabel,
      ),
      DownloadStatus.queued => icon(
        LucideIcons300.clock,
        c.inkFaint,
        AppText.downloadWaiting,
      ),
      DownloadStatus.failed => icon(
        LucideIcons300.circleAlert,
        c.accentText,
        AppText.downloadFailed,
      ),
      DownloadStatus.downloading => Text(
        download.pageCount == 0
            ? '…'
            : '${download.savedPages}/${download.pageCount}',
        style: DotlineText.data.copyWith(color: c.ink),
      ),
    };
  }
}
