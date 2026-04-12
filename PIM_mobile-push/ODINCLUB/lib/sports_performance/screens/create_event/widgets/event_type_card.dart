import 'package:flutter/material.dart';
import '../../../theme/sp_colors.dart';
import '../../../theme/sp_typography.dart';
import '../../../models/event.dart';

class EventTypeCard extends StatelessWidget {
  final EventType type;
  final bool isSelected;
  final VoidCallback onTap;

  const EventTypeCard({
    super.key,
    required this.type,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            color: isSelected 
                ? SPColors.primaryBlue.withOpacity(0.1) 
                : SPColors.backgroundSecondary.withOpacity(0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? SPColors.primaryBlue : SPColors.borderPrimary.withOpacity(0.3),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _getIcon(),
                color: isSelected ? SPColors.primaryBlue : SPColors.textTertiary,
                size: 28,
              ),
              const SizedBox(height: 8),
              Text(
                _getLabel(),
                style: SPTypography.bodyMedium.copyWith(
                  color: isSelected ? Colors.white : SPColors.textTertiary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIcon() {
    switch (type) {
      case EventType.testSession:
        return Icons.speed_outlined;
      case EventType.match:
        return Icons.sports_soccer_outlined;
      case EventType.evaluation:
        return Icons.assignment_outlined;
      case EventType.detection:
        return Icons.visibility_outlined;
      case EventType.medical:
        return Icons.medical_services_outlined;
      case EventType.recovery:
        return Icons.self_improvement_outlined;
      case EventType.aiAnalysis:
        return Icons.psychology_outlined;
    }
  }

  String _getLabel() {
    switch (type) {
      case EventType.testSession:
        return 'Session de Test';
      case EventType.match:
        return 'Match';
      case EventType.evaluation:
        return 'Évaluation';
      case EventType.detection:
        return 'Détection';
      case EventType.medical:
        return 'Médical';
      case EventType.recovery:
        return 'Récupération';
      case EventType.aiAnalysis:
        return 'Analyse IA';
    }
  }
}
