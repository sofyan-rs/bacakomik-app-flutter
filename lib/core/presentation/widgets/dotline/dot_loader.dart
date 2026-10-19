import 'package:bacakomik_app/core/theme/dotline_colors.dart';
import 'package:bacakomik_app/core/theme/dotline_tokens.dart';
import 'package:flutter/material.dart';

/// Five dots with a light that moves across them. Replaces spinners.
class DotLoader extends StatefulWidget {
  const DotLoader({super.key, this.dots = 5});

  final int dots;

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
      label: 'Memuat',
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final head = (_controller.value * widget.dots).floor();
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
                        ? c.ink
                        : i == head - 1
                        ? c.inkMuted
                        : c.lineStrong,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
