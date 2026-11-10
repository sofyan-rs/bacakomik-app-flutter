import 'package:flutter/painting.dart';

/// Dotline type scale. Colors come from the surrounding [DefaultTextStyle] or
/// `.copyWith(color: ...)`. See `docs/ARCHITECTURE.md` §5.
///
/// Doto is only for screen titles and the app name, never below 22px.
/// Numbers inside a screen use [stat] / [statS]. [label] is always uppercase.
abstract final class DotlineText {
  static const _doto = 'Doto';
  static const _geist = 'Geist';
  static const _mono = 'GeistMono';

  static TextStyle _style(
    String family,
    double size,
    double lineHeight,
    FontWeight weight, [
    double tracking = 0,
  ]) => TextStyle(
    fontFamily: family,
    fontSize: size,
    height: lineHeight / size,
    fontWeight: weight,
    letterSpacing: tracking * size,
  );

  /// Uppercase screen title: `HOME`, `EXPLORE`.
  static final dotM = _style(_doto, 22, 26, FontWeight.w700);

  /// App name on the splash screen.
  static final dotBrand = _style(_doto, 40, 44, FontWeight.w900, .01);

  /// Sheet title, section title, "Chapter 67 finished".
  static final title = _style(_geist, 22, 28, FontWeight.w500, -.01);

  /// Stat tile number.
  static final stat = _style(_geist, 32, 36, FontWeight.w600, -.02);

  /// Three stats in a row.
  static final statS = _style(_geist, 24, 32, FontWeight.w600, -.01);

  /// Row title, large button.
  static final headline = _style(_geist, 17, 24, FontWeight.w500);

  /// Paragraphs, synopsis, buttons.
  static final body = _style(_geist, 15, 22, FontWeight.w400);

  /// Row subtitle, title under a grid cover.
  static final bodyS = _style(_geist, 13, 18, FontWeight.w400);

  /// Overline, chip, segment, type label. Always uppercase.
  static final label = _style(_mono, 11, 14, FontWeight.w400, .12);

  /// `CH. 49`, `12 mnt`, paths, counts.
  static final data = _style(_mono, 13, 18, FontWeight.w400);
}
