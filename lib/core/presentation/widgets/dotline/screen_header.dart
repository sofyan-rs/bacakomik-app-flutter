import 'package:bacakomik_app/core/theme/dotline_colors.dart';
import 'package:bacakomik_app/core/theme/dotline_text.dart';
import 'package:bacakomik_app/core/theme/dotline_tokens.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons_300.dart';

/// Screen title in Doto (`EXPLORE`), with an optional overline above
/// (greeting), a `data` subtitle below ("6 comics · 2 updated") and round
/// actions on the right.
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    super.key,
    required this.title,
    this.overline,
    this.subtitle,
    this.subtitleWidget,
    this.onTitleTap,
    this.titleSemanticLabel,
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

  /// Replaces [subtitle], e.g. a source's domain with a status dot.
  final Widget? subtitleWidget;

  /// Makes the title a dropdown: a chevron follows it and taps call this.
  final VoidCallback? onTitleTap;
  final String? titleSemanticLabel;
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
                if (onTitleTap == null)
                  Semantics(header: true, child: _title(c))
                else
                  Semantics(
                    header: true,
                    button: true,
                    label: titleSemanticLabel,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: onTitleTap,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(child: _title(c)),
                          const SizedBox(width: DotSpace.s2),
                          Icon(
                            LucideIcons300.chevronDown,
                            size: DotSize.icon,
                            color: c.ink,
                          ),
                        ],
                      ),
                    ),
                  ),
                if (subtitleWidget != null) ...[
                  const SizedBox(height: DotSpace.s1),
                  subtitleWidget!,
                ] else if (subtitle != null) ...[
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

  Widget _title(DotlineColors c) => Text(
    title.toUpperCase(),
    style: DotlineText.dotM.copyWith(color: c.ink),
    maxLines: 1,
    overflow: TextOverflow.fade,
    softWrap: false,
  );
}
