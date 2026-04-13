import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class RiskIndicator extends StatelessWidget {
  const RiskIndicator({super.key, required this.probability});

  final double probability;

  @override
  Widget build(BuildContext context) {
    final display = (probability * 100).clamp(0, 100).toDouble();
    final color = _riskColor(display);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 140,
            height: 140,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: display / 100,
                  strokeWidth: 12,
                  backgroundColor: AppTheme.surfaceAlt,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${display.toStringAsFixed(0)}%',
                            style: const TextStyle(
                              fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Risk',
                        style: TextStyle(
                          color: AppTheme.textSecondary.withValues(alpha: 0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FittedBox(
            child: Text(
              _riskLabel(display),
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _riskLabel(double value) {
    if (value < 30) {
      return 'Low risk';
    }
    if (value < 60) {
      return 'Moderate risk';
    }
    return 'High risk';
  }

  Color _riskColor(double value) {
    if (value < 30) {
      return AppTheme.success;
    }
    if (value < 60) {
      return AppTheme.warning;
    }
    return AppTheme.danger;
  }
}
