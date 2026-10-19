import 'package:bacakomik_app/core/theme/dotline_colors.dart';
import 'package:bacakomik_app/core/theme/dotline_text.dart';
import 'package:bacakomik_app/core/theme/dotline_tokens.dart';
import 'package:flutter/material.dart';

/// `surface` tile with a stat number and an `inkFaint` label.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.value,
    required this.label,
    this.compact = false,
    this.labelOnTop = false,
  });

  final String value;
  final String label;

  /// Uses `statS` (three tiles in a row) instead of `stat`.
  final bool compact;

  /// Label above the number (Lainnya) instead of below (Detail).
  final bool labelOnTop;

  @override
  Widget build(BuildContext context) {
    final c = Dotline.of(context);
    final labelText = Text(
      label.toUpperCase(),
      style: DotlineText.label.copyWith(color: c.inkFaint),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
    final valueText = Text(
      value,
      style: (compact ? DotlineText.statS : DotlineText.stat).copyWith(
        color: c.ink,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );

    return Container(
      padding: EdgeInsets.all(compact ? DotSpace.s3 + 2 : DotSpace.s4),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(DotRadius.tile),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: labelOnTop
            ? [labelText, const SizedBox(height: DotSpace.s2), valueText]
            : [valueText, const SizedBox(height: DotSpace.s1), labelText],
      ),
    );
  }
}
