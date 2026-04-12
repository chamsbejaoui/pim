import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/sp_colors.dart';
import '../theme/sp_typography.dart';
import 'package:intl/intl.dart';

class PerformanceProgressionChart extends StatelessWidget {
  final List<dynamic> tests;
  final List<dynamic> matches;

  const PerformanceProgressionChart({
    Key? key,
    required this.tests,
    required this.matches,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (tests.isEmpty && matches.isEmpty) {
      return _buildEmptyState();
    }

    return Container(
      height: 300,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: SPColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: SPColors.borderPrimary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ÉVOLUTION PERFORMANCE',
                style: SPTypography.label.copyWith(color: SPColors.textSecondary),
              ),
              _buildLegend(),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: SPColors.borderPrimary.withOpacity(0.5),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        return const SizedBox.shrink(); // Purely visual for now or use indices
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 20,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: TextStyle(color: SPColors.textTertiary, fontSize: 10),
                        );
                      },
                      reservedSize: 30,
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: (tests.length + matches.length).toDouble() - 1,
                minY: 0,
                maxY: 100,
                lineBarsData: [
                  _buildLineData(tests, SPColors.primaryBlue, 'Tests'),
                  _buildLineData(matches, SPColors.badgeTechnical, 'Matchs'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  LineChartBarData _buildLineData(List<dynamic> data, Color color, String label) {
    return LineChartBarData(
      spots: data.asMap().entries.map((e) {
        return FlSpot(e.key.toDouble(), (e.value['score'] as num).toDouble());
      }).toList(),
      isCurved: true,
      color: color,
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
          radius: 4,
          color: color,
          strokeWidth: 2,
          strokeColor: Colors.white,
        ),
      ),
      belowBarData: BarAreaData(
        show: true,
        color: color.withOpacity(0.1),
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      children: [
        _buildLegendItem('TESTS', SPColors.primaryBlue),
        const SizedBox(width: 12),
        _buildLegendItem('MATCHS', SPColors.badgeTechnical),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: SPColors.textTertiary, fontSize: 8, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: SPColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Center(
        child: Text('Aucune donnée historique disponible', style: TextStyle(color: SPColors.textTertiary)),
      ),
    );
  }
}
