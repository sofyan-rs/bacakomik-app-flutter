import 'package:flutter/material.dart';

/// Dotline color tokens. Dark is the primary theme (pure black for OLED),
/// light mirrors it on `#F2F2F2`. See `docs/ARCHITECTURE.md` §5.
@immutable
class DotlineColors extends ThemeExtension<DotlineColors> {
  const DotlineColors({
    required this.bg,
    required this.surface,
    required this.surfaceRaised,
    required this.line,
    required this.lineStrong,
    required this.ink,
    required this.inkMuted,
    required this.inkFaint,
    required this.onInk,
    required this.accent,
    required this.onAccent,
    required this.accentText,
    required this.positive,
    required this.focus,
    required this.scrim,
    required this.navBar,
    required this.navSelected,
  });

  /// Screen background; list groups inside bottom sheets.
  final Color bg;

  /// Cards, list groups, sheets, menus, segmented containers.
  final Color surface;

  /// Pressed state, search field, cover placeholder, switch track off,
  /// disabled buttons.
  final Color surfaceRaised;

  /// Hairline between rows.
  final Color line;

  /// Control borders and unlit meter dots. Below 3:1, never the only cue.
  final Color lineStrong;

  /// Main text and icons; primary button, switch on, selected segment.
  final Color ink;
  final Color inkMuted;

  /// Captions, times, inactive tab icons. Only on [bg] or [surface].
  final Color inkFaint;
  final Color onInk;

  /// Signal fill: NEW dot, `+3` badge, delete button. One or two per screen.
  final Color accent;
  final Color onAccent;

  /// Red text: "DIHAPUS", NEW label.
  final Color accentText;

  /// Confirmation, always paired with a word or icon.
  final Color positive;
  final Color focus;

  /// Behind sheets and dialogs.
  final Color scrim;

  /// Floating bottom nav pill.
  final Color navBar;

  /// Circle behind the active nav tab.
  final Color navSelected;

  static const dark = DotlineColors(
    bg: Color(0xFF000000),
    surface: Color(0xFF111111),
    surfaceRaised: Color(0xFF1C1C1C),
    line: Color(0x1FFFFFFF),
    lineStrong: Color(0xFF4A4A4A),
    ink: Color(0xFFFFFFFF),
    inkMuted: Color(0xFFA6A6A6),
    inkFaint: Color(0xFF808080),
    onInk: Color(0xFF000000),
    accent: Color(0xFFE5211C),
    onAccent: Color(0xFFFFFFFF),
    accentText: Color(0xFFFF5A52),
    positive: Color(0xFF4AD991),
    focus: Color(0xFFFFFFFF),
    scrim: Color(0xB8000000),
    navBar: Color(0xFF1C1C1C),
    navSelected: Color(0xFF3A3A3A),
  );

  static const light = DotlineColors(
    bg: Color(0xFFF2F2F2),
    surface: Color(0xFFFFFFFF),
    surfaceRaised: Color(0xFFE8E8E8),
    line: Color(0x1A000000),
    lineStrong: Color(0xFFBDBDBD),
    ink: Color(0xFF000000),
    inkMuted: Color(0xFF4D4D4D),
    inkFaint: Color(0xFF6B6B6B),
    onInk: Color(0xFFFFFFFF),
    accent: Color(0xFFD70015),
    onAccent: Color(0xFFFFFFFF),
    accentText: Color(0xFFD70015),
    positive: Color(0xFF0B6B3C),
    focus: Color(0xFF000000),
    scrim: Color(0x66000000),
    navBar: Color(0xFFE2E2E2),
    navSelected: Color(0xFFFFFFFF),
  );

  @override
  DotlineColors copyWith() => this;

  @override
  DotlineColors lerp(DotlineColors? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return DotlineColors(
      bg: l(bg, other.bg),
      surface: l(surface, other.surface),
      surfaceRaised: l(surfaceRaised, other.surfaceRaised),
      line: l(line, other.line),
      lineStrong: l(lineStrong, other.lineStrong),
      ink: l(ink, other.ink),
      inkMuted: l(inkMuted, other.inkMuted),
      inkFaint: l(inkFaint, other.inkFaint),
      onInk: l(onInk, other.onInk),
      accent: l(accent, other.accent),
      onAccent: l(onAccent, other.onAccent),
      accentText: l(accentText, other.accentText),
      positive: l(positive, other.positive),
      focus: l(focus, other.focus),
      scrim: l(scrim, other.scrim),
      navBar: l(navBar, other.navBar),
      navSelected: l(navSelected, other.navSelected),
    );
  }
}

/// Short access: `Dotline.of(context).ink`.
abstract final class Dotline {
  static DotlineColors of(BuildContext context) =>
      Theme.of(context).extension<DotlineColors>()!;
}
