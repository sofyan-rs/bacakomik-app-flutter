import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bacakomik_app/core/constants/colors.dart';

class AppThemes {
  static final darkTheme = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
    ),
    fontFamily: GoogleFonts.rubik().fontFamily,
    navigationBarTheme: const NavigationBarThemeData(
      indicatorColor: AppColors.primary,
      shadowColor: AppColors.dark,
    ),
    navigationRailTheme: const NavigationRailThemeData(
      indicatorColor: AppColors.primary,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.primary,
    ),
  );

  static final lightTheme = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
    ),
    fontFamily: GoogleFonts.rubik().fontFamily,
    navigationBarTheme: const NavigationBarThemeData(
      indicatorColor: AppColors.primary,
      shadowColor: AppColors.dark,
    ),
    navigationRailTheme: const NavigationRailThemeData(
      indicatorColor: AppColors.primary,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.primary,
    ),
  );
}
