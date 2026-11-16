import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:water_tank_controller/core/app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData darkTheme({bool highContrast = false}) {
    final base = ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: highContrast ? Colors.black : AppColors.background,
      colorScheme: ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: highContrast ? const Color(0xFF121212) : AppColors.surface,
        error: AppColors.error,
      ),
    );

    return base.copyWith(
      textTheme: GoogleFonts.interTextTheme(base.textTheme),
      cardTheme: CardTheme(
        color: highContrast ? const Color(0xFF1E1E1E) : AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
    );
  }
}
