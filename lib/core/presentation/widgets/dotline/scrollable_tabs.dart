import 'package:bacakomik_app/core/presentation/widgets/dotline/segmented_control.dart';
import 'package:bacakomik_app/core/theme/dotline_colors.dart';
import 'package:bacakomik_app/core/theme/dotline_text.dart';
import 'package:bacakomik_app/core/theme/dotline_tokens.dart';
import 'package:flutter/material.dart';

/// [SegmentedControl] look for any number of tabs: few tabs share the width,
/// many scroll sideways and the selected one is scrolled into view.
class ScrollableTabs<T> extends StatefulWidget {
  const ScrollableTabs({
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
  State<ScrollableTabs<T>> createState() => _ScrollableTabsState<T>();
}

class _ScrollableTabsState<T> extends State<ScrollableTabs<T>> {
  static const _padding = 4.0;
  static const _tabHeight = 40.0;

  final _keys = <T, GlobalKey>{};

  @override
  void didUpdateWidget(ScrollableTabs<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selected != widget.selected) _reveal();
  }

  void _reveal() => WidgetsBinding.instance.addPostFrameCallback((_) {
    final context = _keys[widget.selected]?.currentContext;
    if (context == null || !context.mounted) return;
    Scrollable.ensureVisible(
      context,
      alignment: 0.5,
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : DotMotion.slide,
      curve: DotMotion.slideCurve,
    );
  });

  @override
  Widget build(BuildContext context) {
    final c = Dotline.of(context);
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : DotMotion.slide;
    final radius = BorderRadius.circular(DotRadius.pill);

    return Container(
      padding: const EdgeInsets.all(_padding),
      decoration: BoxDecoration(
        color: widget.background ?? c.surface,
        borderRadius: radius,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final minWidth = constraints.maxWidth / widget.segments.length;
          return ClipRRect(
            borderRadius: radius,
            child: SizedBox(
              height: _tabHeight,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final segment in widget.segments)
                      ConstrainedBox(
                        key: _keys.putIfAbsent(segment.value, GlobalKey.new),
                        constraints: BoxConstraints(minWidth: minWidth),
                        child: Semantics(
                          button: true,
                          selected: segment.value == widget.selected,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => widget.onChanged(segment.value),
                            child: AnimatedContainer(
                              duration: duration,
                              curve: DotMotion.slideCurve,
                              height: _tabHeight,
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(
                                horizontal: DotSpace.s4,
                              ),
                              decoration: BoxDecoration(
                                color: segment.value == widget.selected
                                    ? c.ink
                                    : Colors.transparent,
                                borderRadius: radius,
                              ),
                              child: _label(c, segment),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Label, then its [Segment.count] smaller and dimmed.
  Widget _label(DotlineColors c, Segment<T> segment) {
    final selected = segment.value == widget.selected;
    final color = selected ? c.onInk : c.inkMuted;
    final label = Text(
      segment.label.toUpperCase(),
      maxLines: 1,
      style: DotlineText.label.copyWith(color: color),
    );
    if (segment.count == null) return label;
    // A Row, not a TextSpan: spans share a baseline, so the smaller count
    // would sit low instead of centred on the label.
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        label,
        const SizedBox(width: DotSpace.s1),
        Text(
          '${segment.count}',
          maxLines: 1,
          style: DotlineText.label.copyWith(
            color: color.withValues(alpha: .6),
            fontSize: 9,
            height: 1,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}
