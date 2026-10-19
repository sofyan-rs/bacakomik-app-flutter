import 'package:bacakomik_app/core/theme/dotline_colors.dart';
import 'package:bacakomik_app/core/theme/dotline_text.dart';
import 'package:bacakomik_app/core/theme/dotline_tokens.dart';
import 'package:flutter/material.dart';

class Segment<T> {
  const Segment({required this.value, required this.label});

  final T value;
  final String label;
}

/// Pill container on `surface` with an `ink` pill that slides to the selected
/// segment. Used for type, favorites filter, theme, reading direction.
class SegmentedControl<T> extends StatelessWidget {
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

  static const _padding = 4.0;
  static const _segmentHeight = 40.0;

  @override
  Widget build(BuildContext context) {
    final c = Dotline.of(context);
    final animate = !MediaQuery.disableAnimationsOf(context);
    final duration = animate ? DotMotion.slide : Duration.zero;
    final index = segments.indexWhere((s) => s.value == selected);
    final count = segments.length;

    return Container(
      padding: const EdgeInsets.all(_padding),
      decoration: BoxDecoration(
        color: background ?? c.surface,
        borderRadius: BorderRadius.circular(DotRadius.pill),
      ),
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
                        onTap: () => onChanged(segments[i].value),
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
    );
  }
}
