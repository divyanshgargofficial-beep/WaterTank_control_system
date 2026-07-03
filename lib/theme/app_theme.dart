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
    final textTheme = GoogleFonts.interTextTheme(ThemeData.light().textTheme);
    return _base(
      scheme: scheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: const Color(0xFFF3F6FA),
      cardColor: Colors.white.withValues(alpha: highContrast ? 1 : 0.92),
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
    final textTheme = GoogleFonts.interTextTheme(
      ThemeData.dark().textTheme,
    ).apply(bodyColor: Colors.white, displayColor: Colors.white);
    return _base(
      scheme: scheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: AppColors.background,
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
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: cardColor.withValues(alpha: 0.96),
        indicatorColor: AppColors.primary.withValues(alpha: 0.22),
        labelTextStyle: WidgetStateProperty.all(textTheme.labelMedium),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
