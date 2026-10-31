import 'package:bacakomik_app/core/theme/dotline_tokens.dart';
import 'package:flutter/material.dart';

/// [header] above a scrolling [body] (Explore, Bookmarks): it slides away
/// while the body scrolls down and comes back as soon as it scrolls up or
/// reaches its top, so the list gets the screen while browsing.
/// [keepShown] holds it in place, e.g. while a search is typed or comics
/// are selected.
class ScrollAwayHeader extends StatefulWidget {
  const ScrollAwayHeader({
    super.key,
    required this.header,
    required this.body,
    this.keepShown = false,
  });

  final Widget header;
  final Widget body;
  final bool keepShown;

  /// How far the body scrolls before the header may hide.
  static const hideAfter = 120.0;

  @override
  State<ScrollAwayHeader> createState() => _ScrollAwayHeaderState();
}

class _ScrollAwayHeaderState extends State<ScrollAwayHeader> {
  var _shown = true;

  bool _onScroll(ScrollUpdateNotification n) {
    if (n.metrics.axis != Axis.vertical) return false;
    final delta = n.scrollDelta ?? 0;
    final shown =
        widget.keepShown ||
        n.metrics.pixels <= 0 ||
        switch (delta) {
          < -2 => true,
          > 2 when n.metrics.pixels > ScrollAwayHeader.hideAfter => false,
          _ => _shown,
        };
    if (shown != _shown) setState(() => _shown = shown);
    return false;
  }

  @override
  void didUpdateWidget(ScrollAwayHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Held in place: it stays shown after, until the next scroll down.
    if (widget.keepShown) _shown = true;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRect(
          child: AnimatedAlign(
            alignment: Alignment.bottomCenter,
            heightFactor: _shown || widget.keepShown ? 1 : 0,
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : DotMotion.slide,
            curve: DotMotion.slideCurve,
            child: widget.header,
          ),
        ),
        Expanded(
          child: NotificationListener<ScrollUpdateNotification>(
            onNotification: _onScroll,
            child: widget.body,
          ),
        ),
      ],
    );
  }
}
