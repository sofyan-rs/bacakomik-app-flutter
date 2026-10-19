import 'package:bacakomik_app/core/presentation/widgets/dotline/pressable.dart';
import 'package:bacakomik_app/core/theme/dotline_colors.dart';
import 'package:bacakomik_app/core/theme/dotline_tokens.dart';
import 'package:flutter/material.dart';

/// 48px round action button on `surface`, used in screen headers and bars.
class RoundIconButton extends StatelessWidget {
  const RoundIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    required this.semanticLabel,
    this.size = DotSize.touchTarget,
    this.iconSize = DotSize.icon,
    this.background,
    this.foreground,
    this.outlined = false,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final String semanticLabel;
  final double size;
  final double iconSize;
  final Color? background;
  final Color? foreground;

  /// Transparent with a `lineStrong` border instead of a `surface` fill.
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final c = Dotline.of(context);
    return Pressable(
      onTap: onTap,
      semanticLabel: semanticLabel,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: outlined ? Colors.transparent : background ?? c.surface,
          border: outlined
              ? Border.all(color: c.lineStrong, width: DotSize.stroke)
              : null,
        ),
        child: Icon(
          icon,
          size: iconSize,
          color: onTap == null ? c.inkFaint : foreground ?? c.ink,
        ),
      ),
    );
  }
}
