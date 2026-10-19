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
  });

  final List<FloatingNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  /// The pill hugs its tabs: circles sit [DotSize.navPadding] apart, the same
  /// gap as between the circles and the pill edge.
  static double widthFor(int count) =>
      DotSize.navPadding * 2 +
      DotSize.navCircle * count +
      DotSize.navPadding * (count - 1);

  /// Left edge of each tab circle inside a track of [width]. The first and
  /// last circles touch the track ends, so they sit concentric with the
  /// pill's rounded ends (same gap on every side); the rest are spread evenly.
  static List<double> circleLefts(double width, int count) {
    if (count == 1) return [(width - DotSize.navCircle) / 2];
    final step = (width - DotSize.navCircle) / (count - 1);
    return [for (var i = 0; i < count; i++) step * i];
  }

  @override
  Widget build(BuildContext context) {
    final c = Dotline.of(context);
    final animate = !MediaQuery.disableAnimationsOf(context);
    final duration = animate ? DotMotion.slide : Duration.zero;

    return SizedBox(
      width: widthFor(items.length),
      child: Container(
        height: DotSize.navHeight,
        padding: const EdgeInsets.all(DotSize.navPadding),
        decoration: BoxDecoration(
          color: c.navBar,
          borderRadius: BorderRadius.circular(DotRadius.pill),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final lefts = circleLefts(constraints.maxWidth, items.length);
            return Stack(
              children: [
                AnimatedPositioned(
                  duration: duration,
                  curve: DotMotion.slideCurve,
                  left: lefts[selectedIndex],
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
                for (var i = 0; i < items.length; i++)
                  Positioned(
                    // Hit area spans halfway to the neighbouring circles.
                    left: i == 0
                        ? 0
                        : (lefts[i - 1] + lefts[i]) / 2 + DotSize.navCircle / 2,
                    right: i == items.length - 1
                        ? 0
                        : constraints.maxWidth -
                              (lefts[i] + lefts[i + 1]) / 2 -
                              DotSize.navCircle / 2,
                    top: 0,
                    bottom: 0,
                    child: Semantics(
                      button: true,
                      selected: i == selectedIndex,
                      label: items[i].label,
                      excludeSemantics: true,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onSelected(i),
                      ),
                    ),
                  ),
                for (var i = 0; i < items.length; i++)
                  Positioned(
                    left: lefts[i],
                    top: 0,
                    width: DotSize.navCircle,
                    height: DotSize.navCircle,
                    child: IgnorePointer(
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
