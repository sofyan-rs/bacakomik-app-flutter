import 'package:yoru/core/theme/dotline_colors.dart';
import 'package:yoru/core/theme/dotline_text.dart';
import 'package:yoru/core/theme/dotline_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Segment<T> {
  const Segment({required this.value, required this.label, this.count});

  final T value;
  final String label;

  /// Shown after the label by [ScrollableTabs], e.g. comics in a category.
  final int? count;
}

/// Pill container on `surface` with an `ink` pill that slides to the selected
/// segment. Used for type, bookmark filter, theme, reading direction.
///
/// Dragging sideways moves the pill to the segment under the finger;
/// letting go selects that segment.
class SegmentedControl<T> extends StatefulWidget {
  const SegmentedControl({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
    this.background,
  });

  final List<Segment<T>> segments;
  final T selected;
  final ValueChanged<T> onChanged;

  /// Defaults to `surface`; inside a sheet use `bg`.
  final Color? background;

  @override
  State<SegmentedControl<T>> createState() => _SegmentedControlState<T>();
}

class _SegmentedControlState<T> extends State<SegmentedControl<T>> {
  static const _padding = 4.0;
  static const _segmentHeight = 40.0;

  /// The segment under the finger while dragging along the control.
  int? _dragIndex;

  void _dragTo(double x, double width) {
    final count = widget.segments.length;
    final index = (x / (width / count)).floor().clamp(0, count - 1);
    if (index == _dragIndex) return;
    final shown =
        _dragIndex ??
        widget.segments.indexWhere((s) => s.value == widget.selected);
    if (index != shown) HapticFeedback.selectionClick();
    setState(() => _dragIndex = index);
  }

  void _endDrag() {
    final index = _dragIndex;
    setState(() => _dragIndex = null);
    if (index == null) return;
    final value = widget.segments[index].value;
    if (value != widget.selected) widget.onChanged(value);
  }

  void _cancelDrag() => setState(() => _dragIndex = null);

  @override
  Widget build(BuildContext context) {
    final c = Dotline.of(context);
    final animate = !MediaQuery.disableAnimationsOf(context);
    final duration = animate ? DotMotion.slide : Duration.zero;
    final segments = widget.segments;
    final index =
        _dragIndex ?? segments.indexWhere((s) => s.value == widget.selected);
    final count = segments.length;

    return Container(
      padding: const EdgeInsets.all(_padding),
      decoration: BoxDecoration(
        color: widget.background ?? c.surface,
        borderRadius: BorderRadius.circular(DotRadius.pill),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) => GestureDetector(
          onHorizontalDragStart: (d) =>
              _dragTo(d.localPosition.dx, constraints.maxWidth),
          onHorizontalDragUpdate: (d) =>
              _dragTo(d.localPosition.dx, constraints.maxWidth),
          onHorizontalDragEnd: (_) => _endDrag(),
          onHorizontalDragCancel: _cancelDrag,
          child: SizedBox(
            height: _segmentHeight,
            child: Stack(
              children: [
                if (index >= 0)
                  AnimatedAlign(
                    duration: duration,
                    curve: DotMotion.slideCurve,
                    alignment: Alignment(
                      count == 1 ? 0 : -1 + 2 * index / (count - 1),
                      0,
                    ),
                    child: FractionallySizedBox(
                      widthFactor: 1 / count,
                      heightFactor: 1,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: c.ink,
                          borderRadius: BorderRadius.circular(DotRadius.pill),
                        ),
                      ),
                    ),
                  ),
                Row(
                  children: [
                    for (var i = 0; i < count; i++)
                      Expanded(
                        child: Semantics(
                          button: true,
                          selected: i == index,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => widget.onChanged(segments[i].value),
                            child: Center(
                              child: AnimatedDefaultTextStyle(
                                duration: duration,
                                style: DotlineText.label.copyWith(
                                  color: i == index ? c.onInk : c.inkMuted,
                                ),
                                child: Text(
                                  segments[i].label.toUpperCase(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
