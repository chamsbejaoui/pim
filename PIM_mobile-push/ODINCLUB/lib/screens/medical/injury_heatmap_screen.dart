import 'package:flutter/material.dart';

import '../../models/medical_result_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/heatmap_widget.dart';
import '../../ui/components/app_section_header.dart';

class InjuryHeatmapScreen extends StatelessWidget {
  const InjuryHeatmapScreen({
    super.key,
    required this.playerName,
    required this.result,
  });

  final String playerName;
  final MedicalResultModel result;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        title: const Text('AI Injury Heatmap'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSectionHeader(title: playerName, subtitle: result.injuryType),
            const SizedBox(height: 16),
            Expanded(
              child: Center(
                child: InjuryHeatmapWidget(
                  injuryType: result.injuryType,
                  injuryProbability: result.injuryProbability,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _LegendRow(probability: result.injuryProbability),
            const SizedBox(height: 8),
            Text(
              'Probability: ${(result.injuryProbability * 100).toStringAsFixed(1)}%',
              style:
                  textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ) ??
                  TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({required this.probability});

  final double probability;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        _LegendItem(label: 'Low', color: AppTheme.success),
        const SizedBox(width: 12),
        _LegendItem(label: 'Medium', color: AppTheme.warning),
        const SizedBox(width: 12),
        _LegendItem(label: 'High', color: AppTheme.danger),
        const Spacer(),
        Text(
          probability < 0.3
              ? 'Low risk'
              : probability < 0.6
              ? 'Moderate risk'
              : 'High risk',
          style:
              textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary) ??
              TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: textTheme.bodySmall ?? const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}
