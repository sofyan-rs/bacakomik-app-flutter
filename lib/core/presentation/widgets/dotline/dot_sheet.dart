import 'package:bacakomik_app/core/presentation/widgets/dotline/pressable.dart';
import 'package:bacakomik_app/core/theme/dotline_colors.dart';
import 'package:bacakomik_app/core/theme/dotline_text.dart';
import 'package:bacakomik_app/core/theme/dotline_tokens.dart';
import 'package:flutter/material.dart';

/// Shows a Dotline bottom sheet: `surface` panel, 28 top corners, dot handle,
/// content padded 16 above the system navigation inset (32 + inset was too
/// far from the bottom edge).
Future<T?> showDotSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool showHandle = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showHandle) const SheetHandle(),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  DotSpace.s4,
                  DotSpace.s4,
                  DotSpace.s4,
                  DotSpace.s4,
                ),
                child: builder(context),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Five 4px `lineStrong` dots, 12 from the top.
class SheetHandle extends StatelessWidget {
  const SheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Dotline.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: DotSpace.s3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < 5; i++)
            Container(
              width: DotSize.dot,
              height: DotSize.dot,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: c.lineStrong,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }
}

/// Action sheet header: 48 icon tile + title + `data` subtitle.
class ActionSheetHeader extends StatelessWidget {
  const ActionSheetHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = Dotline.of(context);
    return Row(
      children: [
        if (icon != null) ...[
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: c.surfaceRaised,
              borderRadius: BorderRadius.circular(DotRadius.m),
            ),
            child: Icon(icon, size: DotSize.icon, color: c.ink),
          ),
          const SizedBox(width: DotSpace.s4),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: DotlineText.title.copyWith(color: c.ink)),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: DotlineText.data.copyWith(color: c.inkFaint),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 72-high `surfaceRaised` tile with an icon above an uppercase label.
class QuickActionTile extends StatelessWidget {
  const QuickActionTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = Dotline.of(context);
    return Pressable(
      onTap: onTap,
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          color: c.surfaceRaised,
          borderRadius: BorderRadius.circular(DotRadius.m),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: DotSize.iconMenu, color: c.ink),
            const SizedBox(height: DotSpace.s2),
            Text(
              label.toUpperCase(),
              style: DotlineText.label.copyWith(color: c.ink),
            ),
          ],
        ),
      ),
    );
  }
}
