import 'package:yoru/core/presentation/widgets/dotline/pressable.dart';
import 'package:yoru/core/theme/dotline_colors.dart';
import 'package:yoru/core/theme/dotline_tokens.dart';
import 'package:material_ui/material_ui.dart';

/// 48px round action button on `surface`, used in screen headers and bars.
/// Under a mouse, [semanticLabel] shows as a tooltip.
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
    // Hover only: a long press on touch keeps doing nothing.
    return Tooltip(
      message: semanticLabel,
      triggerMode: TooltipTriggerMode.manual,
      excludeFromSemantics: true,
      child: Pressable(
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
      ),
    );
  }
}
