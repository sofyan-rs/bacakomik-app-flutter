import 'package:bacakomik_app/core/presentation/widgets/dotline/dot_button.dart';
import 'package:bacakomik_app/core/theme/dotline_colors.dart';
import 'package:bacakomik_app/core/theme/dotline_text.dart';
import 'package:bacakomik_app/core/theme/dotline_tokens.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons_300.dart';

/// Centered icon + title + message, with an optional action. Used for empty
/// lists, "not found" and errors.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  /// No connection, with a retry button.
  const EmptyState.offline({
    super.key,
    this.title = 'No connection',
    this.message = 'Check your internet, then try again.',
    this.actionLabel = 'Try again',
    required this.onAction,
  }) : icon = LucideIcons300.wifiOff;

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final c = Dotline.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DotSpace.s6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: c.inkFaint),
            const SizedBox(height: DotSpace.s4),
            Text(
              title,
              style: DotlineText.headline.copyWith(color: c.ink),
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              const SizedBox(height: DotSpace.s1),
              Text(
                message!,
                style: DotlineText.bodyS.copyWith(color: c.inkMuted),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: DotSpace.s5),
              DotButton.outline(
                label: actionLabel!,
                onTap: onAction,
                size: DotButtonSize.medium,
                expand: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
