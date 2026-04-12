import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppText {
  AppText._();

  static const String fontFamily = 'Inter';

  static TextTheme get textTheme => const TextTheme(
        displayLarge: TextStyle(fontSize: 36, fontWeight: FontWeight.w700),
        displayMedium: TextStyle(fontSize: 30, fontWeight: FontWeight.w700),
        displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
        headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        titleLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        titleSmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
        bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
        labelLarge: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        labelMedium: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        labelSmall: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
      );

  static TextTheme themed(TextTheme base, {required bool isDark}) {
    final color = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final muted = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;

    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(color: color, fontFamily: fontFamily),
      displayMedium: base.displayMedium?.copyWith(color: color, fontFamily: fontFamily),
      displaySmall: base.displaySmall?.copyWith(color: color, fontFamily: fontFamily),
      headlineMedium: base.headlineMedium?.copyWith(color: color, fontFamily: fontFamily),
      headlineSmall: base.headlineSmall?.copyWith(color: color, fontFamily: fontFamily),
      titleLarge: base.titleLarge?.copyWith(color: color, fontFamily: fontFamily),
      titleMedium: base.titleMedium?.copyWith(color: color, fontFamily: fontFamily),
      titleSmall: base.titleSmall?.copyWith(color: color, fontFamily: fontFamily),
      bodyLarge: base.bodyLarge?.copyWith(color: color, fontFamily: fontFamily),
      bodyMedium: base.bodyMedium?.copyWith(color: color, fontFamily: fontFamily),
      bodySmall: base.bodySmall?.copyWith(color: muted, fontFamily: fontFamily),
      labelLarge: base.labelLarge?.copyWith(color: color, fontFamily: fontFamily),
      labelMedium: base.labelMedium?.copyWith(color: muted, fontFamily: fontFamily),
      labelSmall: base.labelSmall?.copyWith(color: muted, fontFamily: fontFamily),
    );
  }
}
