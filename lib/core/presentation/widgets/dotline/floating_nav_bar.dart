import 'package:bacakomik_app/core/theme/dotline_colors.dart';
import 'package:bacakomik_app/core/theme/dotline_tokens.dart';
import 'package:flutter/material.dart';

class FloatingNavItem {
  const FloatingNavItem({required this.icon, required this.label});

  final IconData icon;

  /// Read by screen readers only; the bar shows icons without text.
  final String label;
}

/// Floating pill bottom navigation. A `navSelected` circle slides behind the
/// active tab. Place it in a [Stack] above the content; see [floatingNavInset].
class FloatingNavBar extends StatelessWidget {
  const FloatingNavBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
    this.maxWidth = 360,
  });

  final List<FloatingNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final c = Dotline.of(context);
    final animate = !MediaQuery.disableAnimationsOf(context);
    final duration = animate ? DotMotion.slide : Duration.zero;

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Container(
        height: DotSize.navHeight,
        padding: const EdgeInsets.all(DotSize.navPadding),
        decoration: BoxDecoration(
          color: c.navBar,
          borderRadius: BorderRadius.circular(DotRadius.pill),
          boxShadow: const [shadowFloat],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final slot = constraints.maxWidth / items.length;
            return Stack(
              children: [
                AnimatedPositioned(
                  duration: duration,
                  curve: DotMotion.slideCurve,
                  left: slot * selectedIndex + (slot - DotSize.navCircle) / 2,
                  top: 0,
                  width: DotSize.navCircle,
                  height: DotSize.navCircle,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: c.navSelected,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Row(
                  children: [
                    for (var i = 0; i < items.length; i++)
                      Expanded(
                        child: Semantics(
                          button: true,
                          selected: i == selectedIndex,
                          label: items[i].label,
                          excludeSemantics: true,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => onSelected(i),
                            child: Center(
                              child: TweenAnimationBuilder<Color?>(
                                tween: ColorTween(
                                  end: i == selectedIndex ? c.ink : c.inkFaint,
                                ),
                                duration: duration,
                                builder: (context, color, _) => Icon(
                                  items[i].icon,
                                  color: color,
                                  size: DotSize.icon,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Space a scrollable needs at the bottom so its last item clears the nav.
double floatingNavInset(BuildContext context) =>
    DotSize.navHeight +
    DotSize.navGap +
    MediaQuery.viewPaddingOf(context).bottom +
    DotSpace.s4;
