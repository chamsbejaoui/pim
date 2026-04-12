import 'package:flutter/material.dart';
import '../../ui/theme/app_colors.dart';
import '../../ui/theme/app_text.dart';

class FinancePalette {
  static bool _dark = true;

  static void setDarkMode(bool dark) {
    _dark = dark;
  }

  static bool get isDark => _dark;

  static Color get navy => _dark ? AppColors.darkBackground : AppColors.background;
  static Color get blue => _dark ? AppColors.primaryLight : AppColors.primary;
  static Color get cyan => AppColors.accent;
  static Color get ink => _dark ? AppColors.darkTextPrimary : AppColors.textPrimary;
  static Color get soft => _dark ? AppColors.darkSurfaceAlt : AppColors.surfaceAlt;
  static Color get card => _dark ? AppColors.darkSurface : AppColors.surface;
  static Color get success => AppColors.success;
  static Color get danger => AppColors.danger;
  static Color get warning => AppColors.warning;
  static Color get scaffold => _dark ? AppColors.darkBackground : AppColors.background;
  static Color get muted => _dark ? AppColors.darkTextSecondary : AppColors.textSecondary;
}

ThemeData buildFinanceLightTheme() {
  return _buildFinanceTheme(brightness: Brightness.light);
}

ThemeData buildFinanceDarkTheme() {
  return _buildFinanceTheme(brightness: Brightness.dark);
}

ThemeData _buildFinanceTheme({required Brightness brightness}) {
  const base = TextTheme(
    headlineLarge: TextStyle(
      fontSize: 30,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.8,
    ),
    headlineMedium: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.4,
    ),
    titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
    titleMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
    bodyLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
    bodyMedium: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    scaffoldBackgroundColor: FinancePalette.scaffold,
    colorScheme: ColorScheme.fromSeed(
      seedColor: FinancePalette.blue,
      brightness: brightness,
      primary: FinancePalette.blue,
      secondary: FinancePalette.cyan,
      surface: FinancePalette.card,
      error: FinancePalette.danger,
      onPrimary: Colors.white,
      onSurface: FinancePalette.ink,
    ),
    textTheme: AppText.themed(base, isDark: brightness == Brightness.dark).apply(
      bodyColor: FinancePalette.ink,
      displayColor: FinancePalette.ink,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: FinancePalette.card,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: FinancePalette.card,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: FinancePalette.soft),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: FinancePalette.soft),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: FinancePalette.blue, width: 1.5),
      ),
    ),
  );
}
