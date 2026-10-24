import 'package:bacakomik_app/core/theme/dotline_colors.dart';
import 'package:bacakomik_app/core/theme/dotline_text.dart';
import 'package:bacakomik_app/core/theme/dotline_tokens.dart';
import 'package:flutter/material.dart';

/// Section overline ("NEW SERIES") with an optional action ("SEE ALL").
class SectionLabel extends StatelessWidget {
  const SectionLabel({
    super.key,
    required this.label,
    this.actionLabel,
    this.onAction,
    this.padding = const EdgeInsets.symmetric(horizontal: DotSpace.s4),
  });

  final String label;
  final String? actionLabel;
  final VoidCallback? onAction;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final c = Dotline.of(context);
    return Padding(
      padding: padding,
      child: SizedBox(
        height: DotSize.touchTarget,
        child: Row(
          children: [
            Expanded(
              child: Text(
                label.toUpperCase(),
                style: DotlineText.label.copyWith(color: c.inkFaint),
              ),
            ),
            if (actionLabel != null)
              Semantics(
                button: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onAction,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: DotSpace.s3),
                    child: Text(
                      actionLabel!.toUpperCase(),
                      style: DotlineText.label.copyWith(color: c.ink),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
