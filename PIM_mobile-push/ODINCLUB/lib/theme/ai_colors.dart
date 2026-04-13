import 'package:flutter/material.dart';

/// Color palette for the AI scouting module.
/// NOW ALIGNED with SPColors for visual consistency.
class AiColors {
  AiColors._();

  // Primary — matches SPColors.primaryBlue
  static const Color primary = Color(0xFF5B7CFF);
  static const Color primaryLight = Color(0xFF7B96FF);
  static const Color primaryDark = Color(0xFF4C6FFF);

  // Backgrounds — matches SPColors backgrounds
  static const Color backgroundDark = Color(0xFF0A0E1A);

  // Cards & Surfaces
  static const Color cardDark = Color(0xFF141825);

  // Borders — matches SPColors.borderPrimary
  static const Color borderDark = Color(0xFF2D3648);

  // Text — matches SPColors text system
  static const Color textSecondary = Color(0xFFB8BCC8);
  static const Color textTertiary = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFFB8BCC8);

  // Status — matches SPColors status colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  static Color matchColor(double percentage) {
    if (percentage >= 90) return primary;
    if (percentage >= 80) return success;
    if (percentage >= 70) return warning;
    return textSecondary;
  }

  // Glass effect — matches SP card style (backgroundSecondary with border)
  static const Color glassBackground = Color(0xFF141825);
  static const Color glassBorder = Color(0xFF2D3648);
}
