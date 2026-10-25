import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:bacakomik_app/core/presentation/widgets/dotline/dotline.dart';
import 'package:bacakomik_app/core/theme/dotline_colors.dart';
import 'package:bacakomik_app/core/theme/dotline_text.dart';
import 'package:bacakomik_app/core/theme/dotline_tokens.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons_300.dart';

/// Confirms clearing the chapter page cache and shows what is kept. Pops `true`
/// to clear.
class ClearCacheSheet extends StatelessWidget {
  const ClearCacheSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Dotline.of(context);

    Widget status(String text, Color color) => Text(
      text.toUpperCase(),
      style: DotlineText.label.copyWith(color: color),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ActionSheetHeader(
          icon: LucideIcons300.trash2,
          title: AppText.clearCache,
          subtitle: AppText.clearCacheScope,
        ),
        const SizedBox(height: DotSpace.s4),
        Text(
          AppText.clearCacheConfirmation,
          style: DotlineText.body.copyWith(color: c.inkMuted),
        ),
        const SizedBox(height: DotSpace.s4),
        ListGroup(
          background: c.bg,
          children: [
            ListRow(
              icon: LucideIcons300.image,
              title: AppText.cacheImages,
              trailing: status(AppText.removed, c.accentText),
            ),
            ListRow(
              icon: LucideIcons300.bookImage,
              title: AppText.cacheCovers,
              trailing: status(AppText.kept, c.inkFaint),
            ),
            ListRow(
              icon: LucideIcons300.bookmark,
              title: AppText.bookmark,
              trailing: status(AppText.kept, c.inkFaint),
            ),
            ListRow(
              icon: LucideIcons300.history,
              title: AppText.history,
              trailing: status(AppText.kept, c.inkFaint),
            ),
            ListRow(
              icon: LucideIcons300.download,
              title: AppText.downloads,
              trailing: status(AppText.kept, c.inkFaint),
            ),
          ],
        ),
        const SizedBox(height: DotSpace.s5),
        DotButton.destructive(
          label: AppText.clearCache,
          onTap: () => Navigator.of(context).pop(true),
        ),
        const SizedBox(height: DotSpace.s3),
        DotButton.outline(
          label: AppText.cancel,
          onTap: () => Navigator.of(context).pop(false),
        ),
      ],
    );
  }
}
