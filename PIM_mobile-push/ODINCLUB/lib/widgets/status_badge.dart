import 'package:flutter/material.dart';

import '../ui/theme/medical_theme.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final normalized = status.trim().isEmpty ? 'SAFE' : status.toUpperCase();
    final color = _statusColor(normalized);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        normalized,
        style:
            textTheme.labelLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ) ??
            TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'INJURED':
        return MedicalTheme.danger;
      case 'WARNING':
        return MedicalTheme.warning;
      case 'SAFE':
      default:
        return MedicalTheme.success;
    }
  }
}
