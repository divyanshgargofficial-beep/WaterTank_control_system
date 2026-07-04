import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:water_tank_controller/core/app_colors.dart';
import 'package:water_tank_controller/models/app_settings.dart';

class AppTheme {
  AppTheme._();

  static ThemeMode toFlutterThemeMode(
    AppThemeMode mode,
    Brightness platformBrightness,
  ) {
    return switch (mode) {
      AppThemeMode.dark => ThemeMode.dark,
      AppThemeMode.light => ThemeMode.light,
      AppThemeMode.system =>
        platformBrightness == Brightness.dark
            ? ThemeMode.dark
            : ThemeMode.light,
    };
  }

  static ThemeData light({bool highContrast = false}) {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: const Color(0xFFF7F8FB),
      error: AppColors.danger,
    );
    final textTheme = GoogleFonts.spaceGroteskTextTheme(
      ThemeData.light().textTheme,
    );
    return _base(
      scheme: scheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: const Color(0xFFDDF8FF),
      cardColor: Colors.white.withValues(alpha: highContrast ? 1 : 0.74),
    );
  }

  static ThemeData dark({bool highContrast = false}) {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.card,
      error: AppColors.danger,
    );
    final textTheme = GoogleFonts.spaceGroteskTextTheme(
      ThemeData.dark().textTheme,
    ).apply(bodyColor: AppColors.foam, displayColor: AppColors.foam);
    return _base(
      scheme: scheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: Colors.transparent,
      cardColor: AppColors.card.withValues(alpha: highContrast ? 1 : 0.78),
    );
  }

  static ThemeData _base({
    required ColorScheme scheme,
    required TextTheme textTheme,
    required Color scaffoldBackgroundColor,
    required Color cardColor,
  }) {
    return ThemeData(
      useMaterial3: true,
      brightness: scheme.brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffoldBackgroundColor,
      textTheme: textTheme,
      iconTheme: IconThemeData(color: scheme.onSurface),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.09),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.14)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppColors.secondary, width: 1.4),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.deepSea.withValues(alpha: 0.84),
        indicatorColor: AppColors.secondary.withValues(alpha: 0.18),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.all(textTheme.labelMedium),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.abyss,
          textStyle: const TextStyle(fontWeight: FontWeight.w900),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.deepSea,
        contentTextStyle: const TextStyle(color: AppColors.foam),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }
}
