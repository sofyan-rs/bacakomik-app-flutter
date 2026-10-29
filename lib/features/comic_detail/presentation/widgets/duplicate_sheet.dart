import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:bacakomik_app/core/di/injection.dart';
import 'package:bacakomik_app/core/presentation/widgets/dotline/dotline.dart';
import 'package:bacakomik_app/core/source/extension_manager.dart';
import 'package:bacakomik_app/core/theme/dotline_colors.dart';
import 'package:bacakomik_app/core/theme/dotline_text.dart';
import 'package:bacakomik_app/core/theme/dotline_tokens.dart';
import 'package:bacakomik_app/features/bookmark/domain/entities/bookmark.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons_300.dart';

enum DuplicateChoice { migrate, merge, add, open }

/// Asked when bookmarking a series already bookmarked from another source:
/// move the bookmark and read history here, merge this source into it,
/// keep both as separate entries, or open the bookmarked one. Null when
/// cancelled.
Future<DuplicateChoice?> showDuplicateSheet(
  BuildContext context,
  Bookmark existing,
) {
  final source = getIt<ExtensionManager>().sourceNameOfKey(existing.slug);
  return showDotSheet<DuplicateChoice>(
    context: context,
    builder: (context) {
      final c = Dotline.of(context);
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ActionSheetHeader(
            icon: LucideIcons300.copy,
            title: AppText.duplicateTitle,
            subtitle: '${existing.comicDetails.title} · $source',
          ),
          const SizedBox(height: DotSpace.s4),
          Text(
            '${AppText.duplicateMessagePrefix} $source. '
            '${AppText.duplicateMessage}',
            style: DotlineText.body.copyWith(color: c.inkMuted),
          ),
          const SizedBox(height: DotSpace.s5),
          DotButton(
            label: AppText.migrate,
            leading: LucideIcons300.arrowRightLeft,
            onTap: () => Navigator.of(context).pop(DuplicateChoice.migrate),
          ),
          const SizedBox(height: DotSpace.s3),
          DotButton.outline(
            label: AppText.mergeSources,
            leading: LucideIcons300.gitMerge,
            onTap: () => Navigator.of(context).pop(DuplicateChoice.merge),
          ),
          const SizedBox(height: DotSpace.s3),
          DotButton.outline(
            label: AppText.addAnyway,
            onTap: () => Navigator.of(context).pop(DuplicateChoice.add),
          ),
          const SizedBox(height: DotSpace.s3),
          DotButton.outline(
            label: AppText.viewBookmarkedSeries,
            onTap: () => Navigator.of(context).pop(DuplicateChoice.open),
          ),
          const SizedBox(height: DotSpace.s3),
          DotButton.outline(
            label: AppText.cancel,
            onTap: () => Navigator.of(context).pop(),
          ),
        ],
      );
    },
  );
}
