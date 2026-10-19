import 'package:bacakomik_app/core/theme/dotline_colors.dart';
import 'package:bacakomik_app/core/theme/dotline_text.dart';
import 'package:bacakomik_app/core/theme/dotline_tokens.dart';
import 'package:flutter/material.dart';

/// Material theme built from Dotline tokens. Flat surfaces, no ripple, no
/// elevation tint. See `docs/ARCHITECTURE.md` §5.
ThemeData dotlineTheme(DotlineColors c, Brightness brightness) {
  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    fontFamily: 'Geist',
  );

  return base.copyWith(
    scaffoldBackgroundColor: c.bg,
    canvasColor: c.bg,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    splashColor: Colors.transparent,
    colorScheme: ColorScheme(
      brightness: brightness,
      primary: c.ink,
      onPrimary: c.onInk,
      secondary: c.ink,
      onSecondary: c.onInk,
      error: c.accent,
      onError: c.onAccent,
      surface: c.surface,
      onSurface: c.ink,
      surfaceContainerHighest: c.surfaceRaised,
      outline: c.lineStrong,
      outlineVariant: c.line,
    ),
    textTheme: base.textTheme
        .copyWith(
          bodyLarge: DotlineText.body,
          bodyMedium: DotlineText.body,
          bodySmall: DotlineText.bodyS,
          titleLarge: DotlineText.title,
          titleMedium: DotlineText.headline,
          labelSmall: DotlineText.label,
        )
        .apply(bodyColor: c.ink, displayColor: c.ink),
    iconTheme: IconThemeData(color: c.ink, size: DotSize.icon),
    dividerTheme: DividerThemeData(color: c.line, thickness: 1, space: 1),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: c.ink),
    appBarTheme: AppBarTheme(
      backgroundColor: c.bg,
      foregroundColor: c.ink,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: c.surface,
      modalBackgroundColor: c.surface,
      elevation: 0,
      modalElevation: 0,
      surfaceTintColor: Colors.transparent,
      modalBarrierColor: c.scrim,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(DotRadius.l)),
      ),
      showDragHandle: false,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: c.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      barrierColor: c.scrim,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DotRadius.l),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: c.ink,
      contentTextStyle: DotlineText.body.copyWith(color: c.onInk),
      behavior: SnackBarBehavior.floating,
      elevation: 0,
      shape: const StadiumBorder(),
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: c.ink,
      selectionColor: c.ink.withValues(alpha: 0.24),
      selectionHandleColor: c.ink,
    ),
    extensions: [c],
  );
}

abstract final class DotlineThemes {
  static final dark = dotlineTheme(DotlineColors.dark, Brightness.dark);
  static final light = dotlineTheme(DotlineColors.light, Brightness.light);
}
