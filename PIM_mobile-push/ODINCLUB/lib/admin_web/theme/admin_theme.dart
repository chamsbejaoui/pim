import 'package:flutter/material.dart';

class AdminPalette {
  static bool _dark = true;

  static void setDarkMode(bool dark) {
    _dark = dark;
  }

  static bool get isDark => _dark;

  static Color get night =>
      _dark ? const Color(0xFF050B2D) : const Color(0xFF051C34);
  static Color get deep =>
      _dark ? const Color(0xFF121C4D) : const Color(0xFF0A2E57);
  static Color get electric =>
      _dark ? const Color(0xFF2F53FF) : const Color(0xFF1D7BEA);
  static Color get mist =>
      _dark ? const Color(0xFF070E33) : const Color(0xFFF4F7FC);
  static Color get ink =>
      _dark ? const Color(0xFFE9EEFF) : const Color(0xFF122033);
  static Color get muted =>
      _dark ? const Color(0xFFA9B4D9) : const Color(0xFF66718E);
  static Color get surface => _dark ? const Color(0xFF121A43) : Colors.white;
  static Color get panel =>
      _dark ? const Color(0xFF181F4C) : const Color(0xFFF5F8FD);
  static Color get ok => const Color(0xFF1DAA74);
  static Color get danger => const Color(0xFFD64545);
}

ThemeData buildAdminWebLightTheme() {
  return _buildAdminTheme(
    brightness: Brightness.light,
    scaffold: AdminPalette.mist,
    surface: AdminPalette.surface,
    onSurface: AdminPalette.ink,
    border: const Color(0xFFD6DFED),
  );
}

ThemeData buildAdminWebDarkTheme() {
  return _buildAdminTheme(
    brightness: Brightness.dark,
    scaffold: AdminPalette.mist,
    surface: AdminPalette.surface,
    onSurface: AdminPalette.ink,
    border: const Color(0xFF2B356A),
  );
}

ThemeData _buildAdminTheme({
  required Brightness brightness,
  required Color scaffold,
  required Color surface,
  required Color onSurface,
  required Color border,
}) {
  const textTheme = TextTheme(
    headlineLarge: TextStyle(
      fontSize: 40,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.8,
    ),
    headlineMedium: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.4,
    ),
    titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
    bodyLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    scaffoldBackgroundColor: scaffold,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AdminPalette.electric,
      brightness: brightness,
      primary: AdminPalette.electric,
      surface: surface,
      onSurface: onSurface,
    ),
    textTheme: textTheme.apply(
      fontFamily: 'Poppins',
      bodyColor: onSurface,
      displayColor: onSurface,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AdminPalette.electric, width: 1.5),
      ),
    ),
    cardTheme: CardThemeData(
      color: surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
  );
}
