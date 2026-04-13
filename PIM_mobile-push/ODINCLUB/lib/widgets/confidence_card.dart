import 'package:flutter/material.dart';

import '../ui/theme/medical_theme.dart';

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
        color: MedicalTheme.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: MedicalTheme.cardBorder),
        boxShadow: [
          BoxShadow(
            color: MedicalTheme.accentBlue.withOpacity(0.2),
            blurRadius: 16,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.psychology_rounded,
            color: MedicalTheme.accentBlue,
            size: 20,
          ),
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
