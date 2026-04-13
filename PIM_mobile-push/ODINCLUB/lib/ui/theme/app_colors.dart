import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary palette (dark blue + light blue + white)
  static const Color navy = Color(0xFF0B1D3A);
  static const Color primary = Color(0xFF1E3A8A);
  static const Color primaryLight = Color(0xFF3B82F6);
  static const Color accent = Color(0xFF60A5FA);
  static const Color white = Color(0xFFFFFFFF);

  // Neutrals
  static const Color background = Color(0xFFF4F6FB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceAlt = Color(0xFFF1F5F9);
  static const Color border = Color(0xFFE2E8F0);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textMuted = Color(0xFF94A3B8);

  // Status
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);

  // Dark theme support (still within same palette)
  static const Color darkBackground = Color(0xFF0A1220);
  static const Color darkSurface = Color(0xFF121B2E);
  static const Color darkSurfaceAlt = Color(0xFF0E1626);
  static const Color darkBorder = Color(0xFF1E2A44);
  static const Color darkTextPrimary = Color(0xFFE5E7EB);
  static const Color darkTextSecondary = Color(0xFF9CA3AF);
}
