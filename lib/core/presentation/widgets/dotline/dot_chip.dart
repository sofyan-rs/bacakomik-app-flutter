import 'package:bacakomik_app/core/presentation/widgets/dotline/pressable.dart';
import 'package:bacakomik_app/core/theme/dotline_colors.dart';
import 'package:bacakomik_app/core/theme/dotline_text.dart';
import 'package:bacakomik_app/core/theme/dotline_tokens.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons_300.dart';

/// Outline pill chip. Selected chips are filled `ink` with a check icon.
/// [trailing] puts an icon after the label, e.g. a chevron on a chip that
/// opens a picker.
class DotChip extends StatelessWidget {
  const DotChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.trailing,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? trailing;

  @override
  Widget build(BuildContext context) {
    final c = Dotline.of(context);
    final animate = !MediaQuery.disableAnimationsOf(context);
    final foreground = selected ? c.onInk : c.ink;

    return Semantics(
      selected: selected,
      child: Pressable(
        onTap: onTap,
        child: AnimatedContainer(
          duration: animate ? DotMotion.press : Duration.zero,
          curve: DotMotion.pressCurve,
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: DotSpace.s4),
          decoration: BoxDecoration(
            color: selected ? c.ink : Colors.transparent,
            borderRadius: BorderRadius.circular(DotRadius.pill),
            border: Border.all(
              color: selected ? c.ink : c.lineStrong,
              width: DotSize.stroke,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                Icon(LucideIcons300.check, size: 14, color: foreground),
                const SizedBox(width: 6),
              ],
              Text(
                label.toUpperCase(),
                style: DotlineText.label.copyWith(color: foreground),
              ),
              if (trailing case final icon?) ...[
                const SizedBox(width: 6),
                Icon(icon, size: 14, color: foreground),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
