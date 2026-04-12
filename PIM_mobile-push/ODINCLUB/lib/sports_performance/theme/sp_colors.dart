import 'package:flutter/material.dart';

/// Sports Performance Module Color Palette
/// Dark theme with blue primary color
class SPColors {
  SPColors._();

  // Background Colors
  static const Color backgroundPrimary = Color(0xFF0A0E1A);  // Très sombre, presque noir
  static const Color backgroundSecondary = Color(0xFF141825); // Cards/Containers
  static const Color backgroundTertiary = Color(0xFF1E2433);  // Inputs, sections
  
  // Primary Blue - Couleur principale
  static const Color primaryBlue = Color(0xFF5B7CFF);         // Bleu principal (boutons, accents)
  static const Color primaryBlueDark = Color(0xFF4C6FFF);     // Bleu plus foncé
  static const Color primaryBlueLight = Color(0xFF7B96FF);    // Bleu plus clair
  
  // Text Colors
  static const Color textPrimary = Color(0xFFFFFFFF);         // Blanc pur
  static const Color textSecondary = Color(0xFFB8BCC8);       // Gris clair
  static const Color textTertiary = Color(0xFF6B7280);        // Gris moyen
  static const Color textDisabled = Color(0xFF4B5563);        // Gris foncé
  
  // Status Colors
  static const Color success = Color(0xFF10B981);             // Vert (confirmé, complété)
  static const Color warning = Color(0xFFF59E0B);             // Orange (en attente)
  static const Color error = Color(0xFFEF4444);               // Rouge (absent, erreur)
  static const Color info = Color(0xFF3B82F6);                // Bleu info
  
  // Badge Colors
  static const Color badgePhysical = Color(0xFFEF4444);       // Rouge pour physique
  static const Color badgeTechnical = Color(0xFF8B5CF6);      // Violet pour technique
  static const Color badgeMedical = Color(0xFF10B981);        // Vert pour médical
  static const Color badgeMental = Color(0xFF3B82F6);         // Bleu pour mental
  
  // Border Colors
  static const Color borderPrimary = Color(0xFF2D3648);       // Bordures principales
  static const Color borderSecondary = Color(0xFF1E2433);     // Bordures secondaires
  
  // Overlay Colors
  static const Color overlay = Color(0x80000000);             // Overlay semi-transparent
  static const Color shimmer = Color(0xFF2D3648);             // Pour loading shimmer
  
  // Gradient Colors (pour effets spéciaux)
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryBlueDark, primaryBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient cardGradient = LinearGradient(
    colors: [backgroundSecondary, backgroundTertiary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

/// Theme Data pour le module Sports Performance
class SPTheme {
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    
    // Color Scheme
    colorScheme: const ColorScheme.dark(
      primary: SPColors.primaryBlue,
      secondary: SPColors.primaryBlueLight,
      surface: SPColors.backgroundSecondary,
      background: SPColors.backgroundPrimary,
      error: SPColors.error,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: SPColors.textPrimary,
      onBackground: SPColors.textPrimary,
      onError: Colors.white,
    ),
    
    // Scaffold Background
    scaffoldBackgroundColor: SPColors.backgroundPrimary,
    
    // AppBar Theme
    appBarTheme: const AppBarTheme(
      backgroundColor: SPColors.backgroundPrimary,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: SPColors.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: IconThemeData(color: SPColors.textPrimary),
    ),
    
    // Card Theme
    cardTheme: CardThemeData(
      color: SPColors.backgroundSecondary,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: SPColors.borderPrimary, width: 1),
      ),
    ),
    
    // Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: SPColors.backgroundTertiary,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: SPColors.borderPrimary),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: SPColors.borderPrimary),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: SPColors.primaryBlue, width: 2),
      ),
      hintStyle: const TextStyle(color: SPColors.textTertiary),
      labelStyle: const TextStyle(color: SPColors.textSecondary),
    ),
    
    // Elevated Button Theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: SPColors.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    
    // Text Button Theme
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: SPColors.primaryBlue,
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    
    // Icon Theme
    iconTheme: const IconThemeData(
      color: SPColors.textSecondary,
      size: 24,
    ),
    
    // Divider Theme
    dividerTheme: const DividerThemeData(
      color: SPColors.borderPrimary,
      thickness: 1,
      space: 1,
    ),
    
    // Bottom Navigation Bar Theme
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: SPColors.backgroundSecondary,
      selectedItemColor: SPColors.primaryBlue,
      unselectedItemColor: SPColors.textTertiary,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
  );
}
