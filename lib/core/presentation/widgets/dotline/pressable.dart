import 'package:bacakomik_app/core/theme/dotline_tokens.dart';
import 'package:flutter/material.dart';

/// Tap target that shrinks to [DotMotion.pressScale] while pressed.
/// Dotline uses this instead of Material ink ripples. A right click runs
/// [onLongPress]. Under a mouse it shows the click cursor and grows to
/// [hoverScale].
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.semanticLabel,
    this.scale = DotMotion.pressScale,
    this.hoverScale = 1,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final String? semanticLabel;
  final double scale;

  /// Scale while a mouse is over it, e.g. [DotMotion.hoverScale] for covers.
  final double hoverScale;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  var _pressed = false;
  var _hovered = false;

  bool get _enabled => widget.onTap != null || widget.onLongPress != null;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final animate = !MediaQuery.disableAnimationsOf(context);
    return Semantics(
      button: true,
      enabled: _enabled,
      label: widget.semanticLabel,
      child: MouseRegion(
        cursor: _enabled ? SystemMouseCursors.click : MouseCursor.defer,
        onEnter: _enabled ? (_) => setState(() => _hovered = true) : null,
        onExit: (_) {
          if (_hovered) setState(() => _hovered = false);
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          onLongPress: widget.onLongPress,
          // A right click does what a long press does, for mice.
          onSecondaryTap: widget.onLongPress,
          onTapDown: _enabled ? (_) => _setPressed(true) : null,
          onTapUp: _enabled ? (_) => _setPressed(false) : null,
          onTapCancel: _enabled ? () => _setPressed(false) : null,
          child: AnimatedScale(
            scale: _pressed
                ? widget.scale
                : _hovered
                ? widget.hoverScale
                : 1,
            duration: animate ? DotMotion.press : Duration.zero,
            curve: DotMotion.pressCurve,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
