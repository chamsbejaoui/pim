import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class ConfidenceCard extends StatelessWidget {
  const ConfidenceCard({super.key, required this.confidence});

  final double confidence;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final value = (confidence * 100).clamp(0, 100).toDouble();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cardBorder),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentBlue.withOpacity(0.25),
            blurRadius: 16,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.psychology_rounded, color: AppTheme.accentBlue, size: 20),
          const SizedBox(width: 8),
          Text(
            'AI Confidence: ${value.toStringAsFixed(0)}%',
            style:
                textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600) ??
                const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }
}
