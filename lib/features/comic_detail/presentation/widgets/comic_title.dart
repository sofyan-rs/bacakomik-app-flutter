import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:bacakomik_app/core/theme/dotline_colors.dart';
import 'package:bacakomik_app/core/theme/dotline_text.dart';
import 'package:bacakomik_app/core/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Comic title on the details screen. A long press copies it to the
/// clipboard.
class ComicTitle extends StatelessWidget {
  const ComicTitle(this.title, {super.key});

  final String title;

  Future<void> _copy(BuildContext context) async {
    HapticFeedback.mediumImpact();
    await Clipboard.setData(ClipboardData(text: title));
    if (!context.mounted) return;
    showSnackBar(context: context, message: AppText.titleCopied);
  }

  @override
  Widget build(BuildContext context) {
    final c = Dotline.of(context);
    return Semantics(
      onLongPressHint: AppText.copyTitle,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onLongPress: () => _copy(context),
        child: Text(
          title,
          style: DotlineText.title.copyWith(color: c.ink),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
