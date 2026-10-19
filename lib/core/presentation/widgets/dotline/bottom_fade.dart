import 'package:bacakomik_app/core/theme/dotline_colors.dart';
import 'package:flutter/material.dart';

/// Fades scrolled content into `bg` at the bottom of the screen, behind the
/// floating nav. A deliberate exception to Dotline's no-gradient rule
/// (REDESIGN_PLAN D7). Does not take touches.
class BottomFade extends StatelessWidget {
  const BottomFade({super.key, required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    final bg = Dotline.of(context).bg;
    return IgnorePointer(
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [bg.withValues(alpha: 0), bg.withValues(alpha: 0.85), bg],
              stops: const [0, 0.55, 1],
            ),
          ),
        ),
      ),
    );
  }
}
