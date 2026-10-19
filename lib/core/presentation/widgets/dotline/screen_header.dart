import 'package:bacakomik_app/core/theme/dotline_colors.dart';
import 'package:bacakomik_app/core/theme/dotline_text.dart';
import 'package:bacakomik_app/core/theme/dotline_tokens.dart';
import 'package:flutter/material.dart';

/// Screen title in Doto (`JELAJAH`), with an optional overline above
/// (greeting), a `data` subtitle below ("6 komik · 2 ada update") and round
/// actions on the right.
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    super.key,
    required this.title,
    this.overline,
    this.subtitle,
    this.actions = const [],
    this.padding = const EdgeInsets.fromLTRB(
      DotSpace.s4,
      DotSpace.s5,
      DotSpace.s4,
      DotSpace.s5,
    ),
  });

  final String title;
  final String? overline;
  final String? subtitle;
  final List<Widget> actions;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final c = Dotline.of(context);
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (overline != null) ...[
                  Text(
                    overline!.toUpperCase(),
                    style: DotlineText.label.copyWith(color: c.inkFaint),
                  ),
                  const SizedBox(height: DotSpace.s2),
                ],
                Semantics(
                  header: true,
                  child: Text(
                    title.toUpperCase(),
                    style: DotlineText.dotM.copyWith(color: c.ink),
                    maxLines: 1,
                    overflow: TextOverflow.fade,
                    softWrap: false,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: DotSpace.s1),
                  Text(
                    subtitle!,
                    style: DotlineText.data.copyWith(color: c.inkFaint),
                  ),
                ],
              ],
            ),
          ),
          for (final action in actions) ...[
            const SizedBox(width: DotSpace.s2),
            action,
          ],
        ],
      ),
    );
  }
}
