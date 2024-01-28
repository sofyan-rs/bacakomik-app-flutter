import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bacakomik_app/core/constants/colors.dart';

class AppThemes {
  static final darkTheme = ThemeData(
    useMaterial3: true,
    primaryColor: AppColors.primary,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.background,
    fontFamily: GoogleFonts.rubik().fontFamily,
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: AppColors.background,
      indicatorColor: AppColors.primary,
    ),
    navigationRailTheme: const NavigationRailThemeData(
      indicatorColor: AppColors.primary,
    ),
  );
}
