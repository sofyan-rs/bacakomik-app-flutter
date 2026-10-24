import 'package:bacakomik_app/core/theme/dotline_colors.dart';
import 'package:bacakomik_app/core/theme/dotline_tokens.dart';
import 'package:flutter/material.dart';

class FloatingNavItem {
  const FloatingNavItem({required this.icon, required this.label});

  final IconData icon;

  /// Read by screen readers only; the bar shows icons without text.
  final String label;
}

/// Floating pill navigation. A `navSelected` circle slides behind the active
/// tab. Place it in a [Stack] above the content; see [floatingNavInset].
///
/// [Axis.horizontal] is the bottom bar; [Axis.vertical] is the side rail used
/// on wide screens (see [useNavRail] and [floatingRailInset]).
class FloatingNavBar extends StatelessWidget {
  const FloatingNavBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
    this.axis = Axis.horizontal,
  });

  final List<FloatingNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final Axis axis;

  /// The pill hugs its tabs: circles sit [DotSize.navPadding] apart, the same
  /// gap as between the circles and the pill edge. Measured along [axis].
  static double widthFor(int count) =>
      DotSize.navPadding * 2 +
      DotSize.navCircle * count +
      DotSize.navPadding * (count - 1);

  /// Leading edge of each tab circle inside a track of [width]. The first and
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
    final vertical = axis == Axis.vertical;
    final length = widthFor(items.length);

    /// Positions [child] along the main axis, filling the cross axis.
    Widget place({
      double? start,
      double? end,
      double? extent,
      required Widget child,
    }) => vertical
        ? Positioned(
            top: start,
            bottom: end,
            height: extent,
            left: 0,
            right: 0,
            child: child,
          )
        : Positioned(
            left: start,
            right: end,
            width: extent,
            top: 0,
            bottom: 0,
            child: child,
          );

    return Container(
      width: vertical ? DotSize.navHeight : length,
      height: vertical ? length : DotSize.navHeight,
      padding: const EdgeInsets.all(DotSize.navPadding),
      decoration: BoxDecoration(
        color: c.navBar,
        borderRadius: BorderRadius.circular(DotRadius.pill),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final track = vertical ? constraints.maxHeight : constraints.maxWidth;
          final starts = circleLefts(track, items.length);
          return Stack(
            children: [
              AnimatedPositioned(
                duration: duration,
                curve: DotMotion.slideCurve,
                left: vertical ? 0 : starts[selectedIndex],
                top: vertical ? starts[selectedIndex] : 0,
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
                place(
                  // Hit area spans halfway to the neighbouring circles.
                  start: i == 0
                      ? 0
                      : (starts[i - 1] + starts[i]) / 2 + DotSize.navCircle / 2,
                  end: i == items.length - 1
                      ? 0
                      : track -
                            (starts[i] + starts[i + 1]) / 2 -
                            DotSize.navCircle / 2,
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
                place(
                  start: starts[i],
                  extent: DotSize.navCircle,
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
    );
  }
}

/// Whether the nav sits on the left as a rail instead of at the bottom:
/// landscape phones and tablets.
bool useNavRail(BuildContext context) =>
    MediaQuery.sizeOf(context).width >= DotSize.navRailMinWidth;

/// Space a scrollable needs at the bottom so its last item clears the nav.
double floatingNavInset(BuildContext context) =>
    DotSize.navHeight +
    DotSize.navGap +
    MediaQuery.viewPaddingOf(context).bottom +
    DotSpace.s4;

/// Space content needs on the left so it clears the side rail. The screen's
/// own side margin supplies the gap on the rail's right.
double floatingRailInset(BuildContext context) =>
    MediaQuery.viewPaddingOf(context).left + DotSize.navGap + DotSize.navHeight;
