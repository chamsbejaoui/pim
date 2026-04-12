import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/medical_history_record_model.dart';
import '../theme/app_theme.dart';

class HistoryChart extends StatelessWidget {
  const HistoryChart({super.key, required this.records});

  final List<MedicalHistoryRecordModel> records;

  @override
  Widget build(BuildContext context) {
    final points = _buildSpots(records);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Injury history trend',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 140,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: 100,
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: points,
                    isCurved: true,
                    color: AppTheme.accentBlue,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppTheme.accentBlue.withValues(alpha: 0.2),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<FlSpot> _buildSpots(List<MedicalHistoryRecordModel> records) {
    if (records.isEmpty) {
      return const [FlSpot(0, 0)];
    }

    final normalized = records.reversed.toList();
    return List<FlSpot>.generate(normalized.length, (index) {
      final value = (normalized[index].injuryProbability * 100).clamp(0, 100);
      return FlSpot(index.toDouble(), value.toDouble());
    });
  }
}
