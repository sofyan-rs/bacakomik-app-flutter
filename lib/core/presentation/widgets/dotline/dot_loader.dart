import 'package:yoru/core/theme/dotline_colors.dart';
import 'package:yoru/core/theme/dotline_tokens.dart';
import 'package:material_ui/material_ui.dart';

/// Five dots with a light that moves across them. Replaces spinners.
class DotLoader extends StatefulWidget {
  const DotLoader({super.key, this.dots = 5, this.color});

  final int dots;

  /// The light's colour, with the other dots dimmed from it. Defaults to
  /// `ink` lit over `lineStrong` dots; on an `ink` fill pass `onInk`.
  final Color? color;

  @override
  State<DotLoader> createState() => _DotLoaderState();
}

class _DotLoaderState extends State<DotLoader>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: 160 * widget.dots),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = Dotline.of(context);
    return Semantics(
      label: 'Loading',
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final head = (_controller.value * widget.dots).floor();
          final color = widget.color;
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < widget.dots; i++)
                Container(
                  width: DotSize.dot + 2,
                  height: DotSize.dot + 2,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i == head
                        ? color ?? c.ink
                        : i == head - 1
                        ? color?.withValues(alpha: .6) ?? c.inkMuted
                        : color?.withValues(alpha: .25) ?? c.lineStrong,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
