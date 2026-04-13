import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MedicalTheme {
  MedicalTheme._();

  static const Color background = Color(0xFFF5F8FD);
  static const Color backgroundSoft = Color(0xFFE9F0FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceAlt = Color(0xFFF1F5FC);
  static const Color card = surface;
  static const Color cardBorder = Color(0xFFD9E3F0);

  static const Color primaryBlue = Color(0xFF2F6BFF);
  static const Color accentBlue = Color(0xFF3D8CFF);
  static const Color accentTeal = Color(0xFF1CB6B0);

  static const Color textPrimary = Color(0xFF0F1D33);
  static const Color textSecondary = Color(0xFF5B6B82);
  static const Color textMuted = Color(0xFF93A3B8);

  static const Color success = Color(0xFF1AAE7C);
  static const Color warning = Color(0xFFF3A43B);
  static const Color danger = Color(0xFFE15759);

  static LinearGradient get appGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [background, backgroundSoft],
  );

  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: const Color(0xFF0B1D3A).withValues(alpha: 0.06),
      blurRadius: 24,
      offset: const Offset(0, 12),
    ),
  ];

  static BoxDecoration cardDecoration({double radius = 18}) => BoxDecoration(
    color: card,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: cardBorder),
    boxShadow: softShadow,
  );

  static BoxDecoration softCardDecoration({double radius = 16}) =>
      BoxDecoration(
        color: surfaceAlt,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: cardBorder),
      );

  static TextTheme themedText(TextTheme base) {
    final textTheme = GoogleFonts.manropeTextTheme(base);
    return textTheme.copyWith(
      headlineSmall: textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
        color: textPrimary,
      ),
      headlineMedium: textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: textPrimary,
      ),
      titleLarge: textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: textPrimary,
      ),
      titleMedium: textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      titleSmall: textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      bodyLarge: textTheme.bodyLarge?.copyWith(color: textPrimary),
      bodyMedium: textTheme.bodyMedium?.copyWith(color: textSecondary),
      bodySmall: textTheme.bodySmall?.copyWith(color: textMuted),
      labelLarge: textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      labelMedium: textTheme.labelMedium?.copyWith(color: textSecondary),
      labelSmall: textTheme.labelSmall?.copyWith(color: textSecondary),
    );
  }

  static ThemeData theme(ThemeData base) {
    final textTheme = themedText(base.textTheme);
    return base.copyWith(
      scaffoldBackgroundColor: background,
      colorScheme: base.colorScheme.copyWith(
        primary: primaryBlue,
        secondary: accentTeal,
        surface: surface,
        background: background,
        onSurface: textPrimary,
        onBackground: textPrimary,
      ),
      textTheme: textTheme,
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: textPrimary,
        titleTextStyle: textTheme.titleLarge,
        iconTheme: const IconThemeData(color: textPrimary),
      ),
      cardTheme: base.cardTheme.copyWith(
        color: card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: cardBorder),
        ),
      ),
      dividerTheme: const DividerThemeData(color: cardBorder),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        filled: true,
        fillColor: surfaceAlt,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryBlue, width: 1.4),
        ),
        hintStyle: textTheme.bodySmall?.copyWith(color: textMuted),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: surface,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryBlue,
          side: const BorderSide(color: cardBorder),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
    );
  }
}

// Compatibility shim for medical screens still referencing AppTheme.
class AppTheme {
  AppTheme._();

  static Color get background => MedicalTheme.background;
  static Color get surface => MedicalTheme.surface;
  static Color get surfaceAlt => MedicalTheme.surfaceAlt;
  static Color get card => MedicalTheme.card;
  static Color get cardBorder => MedicalTheme.cardBorder;
  static Color get primaryBlue => MedicalTheme.primaryBlue;
  static Color get accentBlue => MedicalTheme.accentBlue;
  static Color get textPrimary => MedicalTheme.textPrimary;
  static Color get textSecondary => MedicalTheme.textSecondary;
  static Color get textMuted => MedicalTheme.textMuted;
  static Color get success => MedicalTheme.success;
  static Color get warning => MedicalTheme.warning;
  static Color get danger => MedicalTheme.danger;

  static LinearGradient get appGradient => MedicalTheme.appGradient;
}

class MedicalThemeScope extends StatelessWidget {
  const MedicalThemeScope({
    super.key,
    required this.child,
    this.applyBackground = true,
  });

  final Widget child;
  final bool applyBackground;

  @override
  Widget build(BuildContext context) {
    final themed = MedicalTheme.theme(Theme.of(context));
    Widget content = child;

    if (applyBackground) {
      content = DecoratedBox(
        decoration: BoxDecoration(gradient: MedicalTheme.appGradient),
        child: content,
      );
    }

    return Theme(
      data: themed,
      child: DefaultTextStyle(
        style: themed.textTheme.bodyMedium ?? const TextStyle(),
        child: content,
      ),
    );
  }
}
