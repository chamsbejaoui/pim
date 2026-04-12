import 'dart:ui';
import 'package:flutter/material.dart';
import '../../theme/ai_colors.dart';

/// Frosted glass chip for quick info display.
class AiGlassChip extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;

  const AiGlassChip({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AiColors.glassBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AiColors.glassBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: iconColor, size: 16),
              const SizedBox(width: 8),
              Text(label,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AiColors.textMuted)),
            ],
          ),
        ),
      ),
    );
  }
}
