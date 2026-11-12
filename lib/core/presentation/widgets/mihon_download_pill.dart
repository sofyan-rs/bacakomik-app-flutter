import 'package:material_ui/material_ui.dart';
import 'package:yoru/core/constants/texts.dart';
import 'package:yoru/core/presentation/widgets/dotline/dot_loader.dart';
import 'package:yoru/core/source/mihon_process_host.dart';
import 'package:yoru/core/theme/dotline_colors.dart';
import 'package:yoru/core/theme/dotline_text.dart';
import 'package:yoru/core/theme/dotline_tokens.dart';

/// A pill at the top of the window while the desktop Mihon host downloads
/// what it needs (its runtime before the first install, Chromium the first
/// time an extension opens a page): tens of MB that would otherwise look
/// like a stuck screen. Nothing on Android, where nothing is downloaded.
class MihonDownloadPill extends StatelessWidget {
  const MihonDownloadPill({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<MihonDownload?>(
      valueListenable: ProcessMihonHost.downloads,
      builder: (context, download, _) {
        if (download == null) return const SizedBox.shrink();
        final c = Dotline.of(context);
        final label = switch (download.kind) {
          MihonDownloadKind.runtime => AppText.downloadingMihonRuntime,
          MihonDownloadKind.browser => AppText.downloadingMihonBrowser,
        };
        return SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: DotSpace.s3),
              child: Material(
                color: c.ink,
                borderRadius: BorderRadius.circular(DotRadius.pill),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DotSpace.s4,
                    vertical: DotSpace.s2,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DotLoader(color: c.onInk),
                      const SizedBox(width: DotSpace.s3),
                      Text(
                        '$label · ${(download.progress * 100).round()}%',
                        style: DotlineText.data.copyWith(color: c.onInk),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
