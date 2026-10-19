import 'package:bacakomik_app/core/theme/dotline_colors.dart';
import 'package:bacakomik_app/core/theme/dotline_tokens.dart';
import 'package:flutter/material.dart';

/// Progress as a row of 4px dots: lit `ink`, unlit `lineStrong`.
/// [dots] is the precision needed (12 bookmarks, 10 history, 22 continue
/// reading, page count in the reader).
class DotMeter extends StatelessWidget {
  const DotMeter({
    super.key,
    required this.value,
    required this.total,
    this.dots = 12,
    this.gap = 3,
    this.dotSize = DotSize.dot,
  });

  final int value;
  final int total;
  final int dots;
  final double gap;
  final double dotSize;

  /// Lit dots for [value] of [total], rounded so any progress shows one dot
  /// and only a full [total] lights every dot.
  static int litDots(int value, int total, int dots) {
    if (total <= 0 || value <= 0) return 0;
    if (value >= total) return dots;
    return (value / total * dots).round().clamp(1, dots - 1);
  }

  @override
  Widget build(BuildContext context) {
    final c = Dotline.of(context);
    final lit = litDots(value, total, dots);
    return Semantics(
      value: '$value dari $total',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < dots; i++)
            Container(
              width: dotSize,
              height: dotSize,
              margin: EdgeInsets.only(right: i == dots - 1 ? 0 : gap),
              decoration: BoxDecoration(
                color: i < lit ? c.ink : c.lineStrong,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }
}
