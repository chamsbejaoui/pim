import 'package:flutter/material.dart';
import '../ui/theme/app_colors.dart';
import '../ui/theme/app_theme.dart';

class CommunicationPalette {
  static Color get primary => AppTheme.primaryBlue;
  static Color get secondary => AppTheme.accentBlue;
  static Color get accent => AppTheme.success;

  static Color scaffold(BuildContext context) {
    return AppTheme.background;
  }

  static Color card(BuildContext context) {
    return AppTheme.card;
  }

  static Color textPrimary(BuildContext context) {
    return AppTheme.textPrimary;
  }

  static Color textMuted(BuildContext context) {
    return AppTheme.textMuted;
  }

  static Color border(BuildContext context) {
    return AppTheme.cardBorder;
  }

  static BoxDecoration backgroundDecoration() {
    return AppTheme.gradientDecoration;
  }
}
