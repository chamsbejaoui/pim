import 'package:flutter/material.dart';
import '../../../theme/sp_colors.dart';
import '../../../theme/sp_typography.dart';

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SPColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SPColors.borderPrimary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: SPTypography.h4.copyWith(color: SPColors.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: SPTypography.caption.copyWith(color: SPColors.textTertiary),
          ),
        ],
      ),
    );
  }
}
