import 'package:bacakomik_app/core/presentation/widgets/dotline/round_icon_button.dart';
import 'package:bacakomik_app/core/theme/dotline_colors.dart';
import 'package:bacakomik_app/core/theme/dotline_text.dart';
import 'package:bacakomik_app/core/theme/dotline_tokens.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons_300.dart';

class DotMenuItem {
  const DotMenuItem({
    required this.label,
    required this.icon,
    required this.onTap,
    this.destructive = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool destructive;
}

/// Round ⋮ button that opens a [width]-wide `surface` menu with hairlines
/// between rows, its right edge under the button's (the buttons sit at the
/// top right, so the menu keeps the screen's margin). The trigger turns
/// `surfaceRaised` while open.
class DotMenuButton extends StatelessWidget {
  const DotMenuButton({
    super.key,
    required this.items,
    this.semanticLabel = 'Menu',
    this.iconSize = DotSize.icon,
  });

  final List<DotMenuItem> items;
  final String semanticLabel;
  final double iconSize;

  static const width = 224.0;

  @override
  Widget build(BuildContext context) {
    final c = Dotline.of(context);
    return MenuAnchor(
      alignmentOffset: const Offset(
        -(width - DotSize.touchTarget),
        DotSpace.s2,
      ),
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(c.surface),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        elevation: const WidgetStatePropertyAll(0),
        shadowColor: const WidgetStatePropertyAll(Colors.transparent),
        padding: const WidgetStatePropertyAll(EdgeInsets.zero),
        fixedSize: const WidgetStatePropertyAll(Size.fromWidth(width)),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DotRadius.m),
            side: BorderSide(color: c.line),
          ),
        ),
      ),
      menuChildren: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const Divider(),
          _DotMenuRow(item: items[i]),
        ],
      ],
      builder: (context, controller, _) => DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: controller.isOpen
              ? [shadowFloat(Theme.of(context).brightness)]
              : null,
        ),
        child: RoundIconButton(
          icon: LucideIcons300.ellipsisVertical,
          semanticLabel: semanticLabel,
          iconSize: iconSize,
          background: controller.isOpen ? c.surfaceRaised : null,
          onTap: () =>
              controller.isOpen ? controller.close() : controller.open(),
        ),
      ),
    );
  }
}

class _DotMenuRow extends StatelessWidget {
  const _DotMenuRow({required this.item});

  final DotMenuItem item;

  @override
  Widget build(BuildContext context) {
    final c = Dotline.of(context);
    final color = item.destructive ? c.accentText : c.ink;
    return MenuItemButton(
      onPressed: item.onTap,
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(
          Size(DotMenuButton.width, 52),
        ),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: DotSpace.s4),
        ),
        overlayColor: WidgetStatePropertyAll(c.surfaceRaised),
        splashFactory: NoSplash.splashFactory,
      ),
      leadingIcon: Icon(item.icon, size: DotSize.iconMenu, color: color),
      child: Text(item.label, style: DotlineText.body.copyWith(color: color)),
    );
  }
}
