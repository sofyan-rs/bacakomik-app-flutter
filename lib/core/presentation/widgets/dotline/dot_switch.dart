import 'package:bacakomik_app/core/theme/dotline_colors.dart';
import 'package:bacakomik_app/core/theme/dotline_tokens.dart';
import 'package:flutter/material.dart';

/// 52×32 switch. On: `ink` track, `onInk` thumb right. Off: `surfaceRaised`
/// track with `lineStrong` border, `inkMuted` thumb left.
class DotSwitch extends StatelessWidget {
  const DotSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.semanticLabel,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = Dotline.of(context);
    final animate = !MediaQuery.disableAnimationsOf(context);
    final duration = animate ? DotMotion.press : Duration.zero;
    final enabled = onChanged != null;

    return Semantics(
      toggled: value,
      enabled: enabled,
      label: semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? () => onChanged!(!value) : null,
        child: Opacity(
          opacity: enabled ? 1 : 0.4,
          child: AnimatedContainer(
            duration: duration,
            curve: DotMotion.pressCurve,
            width: 52,
            height: 32,
            padding: const EdgeInsets.all(3 - DotSize.stroke),
            decoration: BoxDecoration(
              color: value ? c.ink : c.surfaceRaised,
              borderRadius: BorderRadius.circular(DotRadius.pill),
              border: Border.all(
                color: value ? c.ink : c.lineStrong,
                width: DotSize.stroke,
              ),
            ),
            child: AnimatedAlign(
              duration: duration,
              curve: DotMotion.pressCurve,
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: AnimatedContainer(
                duration: duration,
                width: 26 - DotSize.stroke,
                height: 26 - DotSize.stroke,
                decoration: BoxDecoration(
                  color: value ? c.onInk : c.inkMuted,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
