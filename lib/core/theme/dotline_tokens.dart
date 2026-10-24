import 'dart:ui' show Brightness;

import 'package:flutter/animation.dart';
import 'package:flutter/painting.dart';

/// Spacing scale. See `docs/ARCHITECTURE.md` §5.
abstract final class DotSpace {
  /// Label to value, meter dot gap.
  static const s1 = 4.0;

  /// Between chips, icon to label.
  static const s2 = 8.0;

  /// Between grid cards, compact row padding.
  static const s3 = 12.0;

  /// Screen side margin, group padding.
  static const s4 = 16.0;

  /// Between sections.
  static const s5 = 24.0;

  /// Below a `dotM` title, sheet bottom padding.
  static const s6 = 32.0;

  /// Above a hero number.
  static const s7 = 48.0;
}

abstract final class DotRadius {
  /// Small thumbnail (44×60).
  static const s = 8.0;

  /// Cover in a 3-column grid.
  static const cover = 12.0;

  /// List group, search field, large cover, quick tile.
  static const m = 16.0;

  /// Short stat tile, next-chapter card.
  static const tile = 20.0;

  /// Continue-reading card, sheet top, menu, dialog.
  static const l = 28.0;

  /// Buttons, chips, segmented, switch, bottom nav.
  static const pill = 999.0;
}

abstract final class DotSize {
  static const touchTarget = 48.0;
  static const dot = 4.0;
  static const dotPitch = 8.0;
  static const stroke = 1.5;
  static const rowMin = 56.0;
  static const icon = 24.0;
  static const iconMenu = 22.0;
  static const iconSmall = 20.0;

  /// Floating nav pill: height, inner padding, active circle, gap above the
  /// system navigation inset.
  static const navHeight = 64.0;
  static const navPadding = 6.0;
  static const navCircle = 52.0;
  static const navGap = 12.0;

  /// Screens at least this wide move the nav to a left rail.
  static const navRailMinWidth = 600.0;
}

/// Only for floating elements: bottom nav, chapter navigation pill, menus.
/// Softer than the design system's `0x80 / 0,8 / 24`, which read too heavy
/// on device, and lighter still on the light theme.
BoxShadow shadowFloat(Brightness brightness) => BoxShadow(
  color: brightness == Brightness.dark
      ? const Color(0x52000000)
      : const Color(0x14000000),
  offset: const Offset(0, 4),
  blurRadius: 16,
);

abstract final class DotMotion {
  /// Press and toggle.
  static const press = Duration(milliseconds: 140);
  static const pressCurve = Curves.easeOut;

  /// Pressed buttons shrink to this scale.
  static const pressScale = 0.97;

  /// Sliding selection indicators (nav circle, segmented pill).
  static const slide = Duration(milliseconds: 320);
  static const slideCurve = Curves.easeOutCubic;
}
