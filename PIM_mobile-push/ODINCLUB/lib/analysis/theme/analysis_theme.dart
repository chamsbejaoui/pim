import 'package:flutter/material.dart';
import '../../finance/theme/finance_theme.dart';

class AnalysisPalette {
  static void setDarkMode(bool dark) {
    FinancePalette.setDarkMode(dark);
  }

  static Color get bgTop =>
      FinancePalette.isDark ? FinancePalette.scaffold : const Color(0xFFEAF4FF);
  static Color get bgBottom =>
      FinancePalette.isDark ? const Color(0xFF090F36) : const Color(0xFFF8FBFF);
  static Color get panel => FinancePalette.card;
  static Color get panel2 =>
      Color.lerp(FinancePalette.card, FinancePalette.soft, 0.32)!;
  static Color get border => FinancePalette.soft;
  static Color get neonBlue => FinancePalette.blue;
  static Color get electric => FinancePalette.blue;
  static Color get cyan => FinancePalette.cyan;
  static Color get violet =>
      Color.lerp(FinancePalette.blue, FinancePalette.cyan, 0.45)!;
  static Color get mint => FinancePalette.success;
  static Color get text => FinancePalette.ink;
  static Color get muted => FinancePalette.muted;
  static Color get softLine => FinancePalette.soft;
  static Color get danger => FinancePalette.danger;
  static Color get warning => FinancePalette.warning;
  static Color get overlayCard =>
      panel2.withValues(alpha: FinancePalette.isDark ? 0.86 : 0.94);
  static Color get elevatedStroke => neonBlue.withValues(alpha: 0.26);
  static Color get elevatedGlow => neonBlue.withValues(alpha: 0.18);
  static Color get ringBase =>
      panel2.withValues(alpha: FinancePalette.isDark ? 0.75 : 0.9);
  static Color get chipFill =>
      panel2.withValues(alpha: FinancePalette.isDark ? 0.95 : 1);
  static Color get chipBorder => softLine;
  static Color get softTrack =>
      softLine.withValues(alpha: FinancePalette.isDark ? 0.85 : 0.55);
  static Color get dangerSoft =>
      danger.withValues(alpha: FinancePalette.isDark ? 0.18 : 0.1);
  static Color get errorBannerBg =>
      FinancePalette.isDark ? const Color(0xFF17141F) : const Color(0xFFFFF3F6);
  static Color get pitchGrassTop =>
      FinancePalette.isDark ? const Color(0xFF1D3D33) : const Color(0xFF2F6B59);
  static Color get pitchGrassBottom =>
      FinancePalette.isDark ? const Color(0xFF0B1E14) : const Color(0xFF173A2A);
  static Color get pitchLine =>
      FinancePalette.isDark ? const Color(0x66E6FFF2) : const Color(0x88F4FFFB);
  static Color get ringTrackBase =>
      panel2.withValues(alpha: FinancePalette.isDark ? 0.9 : 0.65);
  static Color get blackChip =>
      FinancePalette.isDark ? const Color(0xFF121212) : const Color(0xFF2A2A2A);
}

BoxDecoration analysisShellDecoration() {
  return BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [AnalysisPalette.bgTop, AnalysisPalette.bgBottom],
    ),
  );
}

TextStyle neonSectionStyle() => TextStyle(
  color: AnalysisPalette.neonBlue,
  fontSize: 13,
  letterSpacing: 2.2,
  fontWeight: FontWeight.w700,
);

BoxDecoration glowPanelDecoration({double radius = 24, bool withGlow = false}) {
  return BoxDecoration(
    color: AnalysisPalette.panel,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: AnalysisPalette.softLine),
    boxShadow: withGlow
        ? [
            BoxShadow(
              color: AnalysisPalette.neonBlue.withValues(alpha: 0.22),
              blurRadius: 24,
              spreadRadius: 1,
            ),
          ]
        : [],
  );
}
