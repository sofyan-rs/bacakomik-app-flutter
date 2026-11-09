import 'package:yoru/core/theme/dotline_colors.dart';
import 'package:yoru/core/theme/dotline_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
///
/// Dragging along the bar moves the circle to the tab under the finger;
/// letting go selects that tab.
class FloatingNavBar extends StatefulWidget {
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

  @override
  State<FloatingNavBar> createState() => _FloatingNavBarState();

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
}

class _FloatingNavBarState extends State<FloatingNavBar> {
  /// The tab under the finger while dragging along the bar.
  int? _dragIndex;

  /// The tab whose circle is nearest [offset], given in the bar's own
  /// coordinates (padding included).
  int _indexAt(Offset offset) {
    final count = widget.items.length;
    final along =
        (widget.axis == Axis.vertical ? offset.dy : offset.dx) -
        DotSize.navPadding;
    final track = FloatingNavBar.widthFor(count) - DotSize.navPadding * 2;
    final starts = FloatingNavBar.circleLefts(track, count);
    var best = 0;
    for (var i = 1; i < count; i++) {
      final d = (along - starts[i] - DotSize.navCircle / 2).abs();
      final b = (along - starts[best] - DotSize.navCircle / 2).abs();
      if (d < b) best = i;
    }
    return best;
  }

  void _dragTo(Offset offset) {
    final index = _indexAt(offset);
    if (index == _dragIndex) return;
    if (index != (_dragIndex ?? widget.selectedIndex)) {
      HapticFeedback.selectionClick();
    }
    setState(() => _dragIndex = index);
  }

  void _endDrag() {
    final index = _dragIndex;
    setState(() => _dragIndex = null);
    if (index != null && index != widget.selectedIndex) {
      widget.onSelected(index);
    }
  }

  void _cancelDrag() => setState(() => _dragIndex = null);

  @override
  Widget build(BuildContext context) {
    final c = Dotline.of(context);
    final animate = !MediaQuery.disableAnimationsOf(context);
    final duration = animate ? DotMotion.slide : Duration.zero;
    final items = widget.items;
    final vertical = widget.axis == Axis.vertical;
    final length = FloatingNavBar.widthFor(items.length);
    final selectedIndex = _dragIndex ?? widget.selectedIndex;

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

    final bar = Container(
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
          final starts = FloatingNavBar.circleLefts(track, items.length);
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
                      onTap: () => widget.onSelected(i),
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

    return vertical
        ? GestureDetector(
            onVerticalDragStart: (d) => _dragTo(d.localPosition),
            onVerticalDragUpdate: (d) => _dragTo(d.localPosition),
            onVerticalDragEnd: (_) => _endDrag(),
            onVerticalDragCancel: _cancelDrag,
            child: bar,
          )
        : GestureDetector(
            onHorizontalDragStart: (d) => _dragTo(d.localPosition),
            onHorizontalDragUpdate: (d) => _dragTo(d.localPosition),
            onHorizontalDragEnd: (_) => _endDrag(),
            onHorizontalDragCancel: _cancelDrag,
            child: bar,
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
