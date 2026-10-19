import 'package:bacakomik_app/core/theme/dotline_colors.dart';
import 'package:bacakomik_app/core/theme/dotline_text.dart';
import 'package:bacakomik_app/core/theme/dotline_tokens.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons_300.dart';

/// Rounded group of rows with hairlines between them.
class ListGroup extends StatelessWidget {
  const ListGroup({super.key, required this.children, this.background});

  final List<Widget> children;

  /// Defaults to `surface`; inside a sheet use `bg`.
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final c = Dotline.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(DotRadius.m),
      child: ColoredBox(
        color: background ?? c.surface,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const Divider(),
              children[i],
            ],
          ],
        ),
      ),
    );
  }
}

/// Row inside a [ListGroup]: icon → title + subtitle → value or chevron.
class ListRow extends StatefulWidget {
  const ListRow({
    super.key,
    required this.title,
    this.subtitle,
    this.subtitleWidget,
    this.icon,
    this.leading,
    this.value,
    this.trailing,
    this.onTap,
    this.destructive = false,
    this.showChevron,
  });

  final String title;
  final String? subtitle;

  /// Replaces [subtitle], e.g. a chapter number with a meter.
  final Widget? subtitleWidget;
  final IconData? icon;

  /// Replaces [icon], e.g. a thumbnail.
  final Widget? leading;

  /// `data` text on the right, e.g. `CH. 49` or `TETAP`.
  final String? value;

  /// Replaces [value] and the chevron, e.g. a [DotSwitch].
  final Widget? trailing;
  final VoidCallback? onTap;

  /// Icon and title in `accentText`.
  final bool destructive;

  /// Defaults to true when the row is tappable and has no value/trailing.
  final bool? showChevron;

  @override
  State<ListRow> createState() => _ListRowState();
}

class _ListRowState extends State<ListRow> {
  var _pressed = false;

  @override
  Widget build(BuildContext context) {
    final c = Dotline.of(context);
    final titleColor = widget.destructive ? c.accentText : c.ink;
    final chevron =
        widget.showChevron ??
        (widget.onTap != null &&
            widget.value == null &&
            widget.trailing == null);

    return Semantics(
      button: widget.onTap != null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onTapDown: widget.onTap == null
            ? null
            : (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedContainer(
          duration: DotMotion.press,
          color: _pressed ? c.surfaceRaised : Colors.transparent,
          constraints: const BoxConstraints(minHeight: DotSize.rowMin),
          padding: const EdgeInsets.symmetric(
            horizontal: DotSpace.s4,
            vertical: DotSpace.s3,
          ),
          child: Row(
            children: [
              if (widget.leading != null) ...[
                widget.leading!,
                const SizedBox(width: DotSpace.s4),
              ] else if (widget.icon != null) ...[
                Icon(widget.icon, size: DotSize.icon, color: titleColor),
                const SizedBox(width: DotSpace.s4),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.title,
                      style: DotlineText.headline.copyWith(color: titleColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (widget.subtitleWidget != null) ...[
                      const SizedBox(height: DotSpace.s1),
                      widget.subtitleWidget!,
                    ] else if (widget.subtitle != null)
                      Text(
                        widget.subtitle!,
                        style: DotlineText.bodyS.copyWith(color: c.inkMuted),
                      ),
                  ],
                ),
              ),
              if (widget.trailing != null) ...[
                const SizedBox(width: DotSpace.s3),
                widget.trailing!,
              ] else if (widget.value != null) ...[
                const SizedBox(width: DotSpace.s3),
                Text(
                  widget.value!,
                  style: DotlineText.data.copyWith(color: c.inkFaint),
                ),
              ],
              if (chevron) ...[
                const SizedBox(width: DotSpace.s3),
                Icon(
                  LucideIcons300.chevronRight,
                  size: DotSize.iconSmall,
                  color: c.inkFaint,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
