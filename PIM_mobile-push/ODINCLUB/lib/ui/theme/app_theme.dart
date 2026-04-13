import 'package:flutter/material.dart';
import '../../theme/theme_controller.dart';
import 'app_colors.dart';
import 'app_text.dart';

class AppTheme {
  AppTheme._();

  static bool get _isDark => ThemeController.mode.value == ThemeMode.dark;

  // Compatibility getters for legacy screens
  static Color get blueFonce => _isDark ? AppColors.darkTextPrimary : AppColors.primary;
  static Color get blueCiel => _isDark ? AppColors.primaryLight : AppColors.accent;
  static Color get odinDarkBlue => _isDark ? AppColors.darkSurfaceAlt : AppColors.primary;
  static Color get odinSkyBlue => _isDark ? AppColors.primaryLight : AppColors.accent;
  static Color get white => _isDark ? AppColors.darkSurface : AppColors.surface;
  static Color get lightGrey => _isDark ? AppColors.darkBackground : AppColors.background;
  static Color get darkGrey => _isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
  static Color get strokeDark => _isDark ? AppColors.darkBorder : AppColors.border;

  static Color get background => _isDark ? AppColors.darkBackground : AppColors.background;
  static Color get surface => _isDark ? AppColors.darkSurface : AppColors.surface;
  static Color get surfaceAlt => _isDark ? AppColors.darkSurfaceAlt : AppColors.surfaceAlt;
  static Color get card => surface;
  static Color get cardBorder => _isDark ? AppColors.darkBorder : AppColors.border;
  static Color get primaryBlue => _isDark ? AppColors.primaryLight : AppColors.primary;
  static Color get accentBlue => _isDark ? AppColors.accent : AppColors.primaryLight;
  static Color get textPrimary => _isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
  static Color get textSecondary => _isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
  static Color get textMuted => _isDark ? AppColors.darkTextSecondary : AppColors.textMuted;

  static const Color accentOrange = AppColors.warning;
  static const Color accentGreen = AppColors.success;
  static const Color danger = AppColors.danger;
  static const Color success = AppColors.success;
  static const Color warning = AppColors.warning;

  static ThemeData get lightTheme {
    final base = ThemeData.light();
    final textTheme = AppText.themed(AppText.textTheme, isDark: false);
    return base.copyWith(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.primary,
        secondary: AppColors.primaryLight,
        surface: AppColors.surface,
        background: AppColors.background,
        onPrimary: AppColors.white,
        onSecondary: AppColors.white,
        onSurface: AppColors.textPrimary,
        onBackground: AppColors.textPrimary,
        error: AppColors.danger,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.border),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceAlt,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
        ),
        hintStyle: textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: textTheme.labelLarge,
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    final base = ThemeData.dark();
    final textTheme = AppText.themed(AppText.textTheme, isDark: true);
    return base.copyWith(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBackground,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.primaryLight,
        secondary: AppColors.accent,
        surface: AppColors.darkSurface,
        background: AppColors.darkBackground,
        onPrimary: AppColors.white,
        onSecondary: AppColors.white,
        onSurface: AppColors.darkTextPrimary,
        onBackground: AppColors.darkTextPrimary,
        error: AppColors.danger,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkSurface,
        foregroundColor: AppColors.darkTextPrimary,
        elevation: 0,
        titleTextStyle: textTheme.titleLarge,
        iconTheme: const IconThemeData(color: AppColors.darkTextPrimary),
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.darkBorder),
        ),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.darkBorder),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurfaceAlt,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryLight, width: 1.4),
        ),
        hintStyle: textTheme.bodySmall?.copyWith(color: AppColors.darkTextSecondary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryLight,
          foregroundColor: AppColors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryLight,
          side: const BorderSide(color: AppColors.darkBorder),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: textTheme.labelLarge,
        ),
      ),
    );
  }

  static LinearGradient get appGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: _isDark
            ? [
                AppColors.darkBackground,
                AppColors.darkSurfaceAlt,
                AppColors.darkSurface,
              ]
            : [
                AppColors.background,
                AppColors.surfaceAlt,
                AppColors.surface,
              ],
      );

  static BoxDecoration get gradientDecoration => BoxDecoration(gradient: appGradient);

  static BoxDecoration get buttonGradient => BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _isDark
              ? [AppColors.primaryLight, AppColors.primary]
              : [AppColors.primary, AppColors.primaryLight],
        ),
        borderRadius: BorderRadius.circular(12),
      );

  // Legacy compatibility aliases
  static Color get primaryGreen => blueFonce;
  static Color get lightGreen => blueCiel;
  static const Color darkGreen = AppColors.navy;
}
