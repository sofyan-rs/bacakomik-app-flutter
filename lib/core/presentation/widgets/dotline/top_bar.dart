import 'package:bacakomik_app/core/presentation/widgets/dotline/round_icon_button.dart';
import 'package:bacakomik_app/core/theme/dotline_colors.dart';
import 'package:bacakomik_app/core/theme/dotline_text.dart';
import 'package:bacakomik_app/core/theme/dotline_tokens.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons_300.dart';

/// Bar for pushed screens: round back button, optional title and subtitle,
/// round actions on the right.
class DotTopBar extends StatelessWidget {
  const DotTopBar({
    super.key,
    this.title,
    this.subtitle,
    this.actions = const [],
    this.onBack,
  });

  final String? title;
  final String? subtitle;
  final List<Widget> actions;

  /// Defaults to popping the route.
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final c = Dotline.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DotSpace.s4,
        DotSpace.s2,
        DotSpace.s4,
        DotSpace.s2,
      ),
      child: Row(
        children: [
          RoundIconButton(
            icon: LucideIcons300.chevronLeft,
            semanticLabel: 'Back',
            onTap: onBack ?? () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: DotSpace.s3),
          Expanded(
            child: title == null
                ? const SizedBox.shrink()
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title!,
                        style: DotlineText.headline.copyWith(color: c.ink),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: DotlineText.data.copyWith(color: c.inkFaint),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
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
