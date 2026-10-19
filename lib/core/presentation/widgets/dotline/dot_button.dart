import 'package:bacakomik_app/core/presentation/widgets/dotline/pressable.dart';
import 'package:bacakomik_app/core/theme/dotline_colors.dart';
import 'package:bacakomik_app/core/theme/dotline_text.dart';
import 'package:bacakomik_app/core/theme/dotline_tokens.dart';
import 'package:flutter/material.dart';

enum DotButtonVariant { primary, outline, destructive }

enum DotButtonSize { large, medium }

/// Pill button. Disabled buttons are not faded: primary turns
/// `surfaceRaised` + `inkFaint`, outline turns `line` + `inkFaint`.
class DotButton extends StatelessWidget {
  const DotButton({
    super.key,
    required this.label,
    required this.onTap,
    this.variant = DotButtonVariant.primary,
    this.size = DotButtonSize.large,
    this.leading,
    this.trailing,
    this.expand = true,
  });

  const DotButton.outline({
    super.key,
    required this.label,
    required this.onTap,
    this.size = DotButtonSize.large,
    this.leading,
    this.trailing,
    this.expand = true,
  }) : variant = DotButtonVariant.outline;

  const DotButton.destructive({
    super.key,
    required this.label,
    required this.onTap,
    this.size = DotButtonSize.large,
    this.leading,
    this.trailing,
    this.expand = true,
  }) : variant = DotButtonVariant.destructive;

  final String label;
  final VoidCallback? onTap;
  final DotButtonVariant variant;
  final DotButtonSize size;
  final IconData? leading;
  final IconData? trailing;

  /// Fill the available width.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final c = Dotline.of(context);
    final enabled = onTap != null;

    final (Color fill, Color border, Color foreground) = switch (variant) {
      _ when !enabled && variant == DotButtonVariant.outline => (
        Colors.transparent,
        c.line,
        c.inkFaint,
      ),
      _ when !enabled => (c.surfaceRaised, c.surfaceRaised, c.inkFaint),
      DotButtonVariant.primary => (c.ink, c.ink, c.onInk),
      DotButtonVariant.outline => (Colors.transparent, c.lineStrong, c.ink),
      DotButtonVariant.destructive => (c.accent, c.accent, c.onAccent),
    };

    final style =
        (size == DotButtonSize.large
                ? DotlineText.headline
                : DotlineText.body.copyWith(fontWeight: FontWeight.w500))
            .copyWith(color: foreground);

    return Pressable(
      onTap: onTap,
      child: Container(
        height: size == DotButtonSize.large ? 56 : 48,
        width: expand ? double.infinity : null,
        padding: const EdgeInsets.symmetric(horizontal: DotSpace.s5),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(DotRadius.pill),
          border: Border.all(color: border, width: DotSize.stroke),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (leading != null) ...[
              Icon(leading, size: DotSize.iconSmall, color: foreground),
              const SizedBox(width: DotSpace.s2),
            ],
            Flexible(
              child: Text(
                label,
                style: style,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: DotSpace.s2),
              Icon(trailing, size: DotSize.iconSmall, color: foreground),
            ],
          ],
        ),
      ),
    );
  }
}
