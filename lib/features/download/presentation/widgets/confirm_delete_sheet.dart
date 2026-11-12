import 'package:yoru/core/constants/texts.dart';
import 'package:yoru/core/presentation/widgets/dotline/dotline.dart';
import 'package:yoru/core/theme/dotline_colors.dart';
import 'package:yoru/core/theme/dotline_text.dart';
import 'package:yoru/core/theme/dotline_tokens.dart';
import 'package:material_ui/material_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons_300.dart';

/// Asks before deleting downloads. True when confirmed.
Future<bool> showConfirmDeleteSheet(
  BuildContext context, {
  required String title,
  required String message,
  String? subtitle,
}) async {
  final confirmed = await showDotSheet<bool>(
    context: context,
    builder: (context) {
      final c = Dotline.of(context);
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ActionSheetHeader(
            icon: LucideIcons300.trash2,
            title: title,
            subtitle: subtitle,
          ),
          const SizedBox(height: DotSpace.s4),
          Text(message, style: DotlineText.body.copyWith(color: c.inkMuted)),
          const SizedBox(height: DotSpace.s5),
          DotButton.destructive(
            label: AppText.delete,
            onTap: () => Navigator.of(context).pop(true),
          ),
          const SizedBox(height: DotSpace.s3),
          DotButton.outline(
            label: AppText.cancel,
            onTap: () => Navigator.of(context).pop(false),
          ),
        ],
      );
    },
  );
  return confirmed ?? false;
}
