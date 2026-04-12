import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../theme/ai_colors.dart';
import '../../models/ai_player.dart';

/// Side-by-side radar chart & stat comparison of 2 players.
class AiComparePlayersScreen extends StatelessWidget {
  final AiPlayer playerA;
  final AiPlayer playerB;

  const AiComparePlayersScreen({
    super.key,
    required this.playerA,
    required this.playerB,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AiColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AiColors.backgroundDark,
        title: const Text('Compare Players',
            style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          _buildPlayerHeaders(),
          const SizedBox(height: 20),
          _buildRadarChart(),
          const SizedBox(height: 24),
          _buildStatComparison(),
          const SizedBox(height: 24),
          _buildAiComparison(),
          const SizedBox(height: 40),
        ]),
      ),
    );
  }

  Widget _buildPlayerHeaders() {
    return Row(children: [
      Expanded(child: _playerHeader(playerA, AiColors.primary)),
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 12),
        child: Text('VS',
            style: TextStyle(
                color: AiColors.textSecondary,
                fontWeight: FontWeight.bold,
                fontSize: 18)),
      ),
      Expanded(child: _playerHeader(playerB, AiColors.info)),
    ]);
  }

  Widget _playerHeader(AiPlayer p, Color color) {
    return _glassCard(
      child: Column(children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: color.withOpacity(0.2),
          child: Text(
            p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
            style: TextStyle(
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 8),
        Text(p.name,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14)),
        const SizedBox(height: 4),
        Text(p.position ?? '-',
            style: const TextStyle(
                color: AiColors.textSecondary, fontSize: 12)),
        const SizedBox(height: 6),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${p.computedMatchPercentage}% match',
            style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.bold),
          ),
        ),
      ]),
    );
  }

  Widget _buildRadarChart() {
    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.hexagon_outlined,
                color: AiColors.primary, size: 20),
            SizedBox(width: 8),
            Text('Radar Comparison',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AiColors.primary)),
          ]),
          const SizedBox(height: 16),
          SizedBox(
            height: 280,
            child: CustomPaint(
              size: const Size(double.infinity, 280),
              painter: _RadarChartPainter(
                playerA: _getPlayerStats(playerA),
                playerB: _getPlayerStats(playerB),
                labels: _statLabels,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _dot(AiColors.primary),
              const SizedBox(width: 4),
              Text(playerA.name,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 12)),
              const SizedBox(width: 20),
              _dot(AiColors.info),
              const SizedBox(width: 4),
              Text(playerB.name,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dot(Color c) => Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
          color: c, borderRadius: BorderRadius.circular(5)));

  Widget _buildStatComparison() {
    final statsA = _getPlayerStatsMap(playerA);
    final statsB = _getPlayerStatsMap(playerB);

    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.bar_chart,
                color: AiColors.success, size: 20),
            SizedBox(width: 8),
            Text('Stats Breakdown',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AiColors.success)),
          ]),
          const SizedBox(height: 16),
          ...statsA.entries.map((e) {
            final a = e.value;
            final b = statsB[e.key] ?? 0;
            return _comparisonBar(e.key, a, b);
          }),
        ],
      ),
    );
  }

  Widget _comparisonBar(String label, double a, double b) {
    final maxVal = max(a, b) * 1.3;
    if (maxVal == 0) return const SizedBox.shrink();
    final ratioA = (a / maxVal).clamp(0.0, 1.0);
    final ratioB = (b / maxVal).clamp(0.0, 1.0);
    final aWins = a >= b;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(a.toStringAsFixed(1),
                style: TextStyle(
                    color: aWins ? AiColors.primary : AiColors.textSecondary,
                    fontSize: 11,
                    fontWeight:
                        aWins ? FontWeight.bold : FontWeight.normal)),
            Text(label.toUpperCase(),
                style: const TextStyle(
                    color: AiColors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5)),
            Text(b.toStringAsFixed(1),
                style: TextStyle(
                    color: !aWins ? AiColors.info : AiColors.textSecondary,
                    fontSize: 11,
                    fontWeight:
                        !aWins ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
        const SizedBox(height: 4),
        Row(children: [
          Expanded(
            child: Row(children: [
              Expanded(child: Container()),
              SizedBox(
                width: 120 * ratioA,
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: AiColors.primary,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ]),
          ),
          const SizedBox(width: 4),
          Container(
              width: 1,
              height: 12,
              color: Colors.white.withOpacity(0.2)),
          const SizedBox(width: 4),
          Expanded(
            child: Row(children: [
              SizedBox(
                width: 120 * ratioB,
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: AiColors.info,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ]),
          ),
        ]),
      ]),
    );
  }

  Widget _buildAiComparison() {
    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.psychology,
                color: AiColors.warning, size: 20),
            SizedBox(width: 8),
            Text('AI Verdict',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AiColors.warning)),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _verdictColumn(playerA, AiColors.primary)),
            const SizedBox(width: 12),
            Expanded(child: _verdictColumn(playerB, AiColors.info)),
          ]),
        ],
      ),
    );
  }

  Widget _verdictColumn(AiPlayer p, Color color) {
    return Column(children: [
      Text(p.name,
          style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 13)),
      const SizedBox(height: 8),
      Text('${p.computedMatchPercentage}%',
          style: TextStyle(
              color: color,
              fontSize: 28,
              fontWeight: FontWeight.bold)),
      const SizedBox(height: 4),
      Text(p.clusterProfile ?? '-',
          style: const TextStyle(
              color: AiColors.textSecondary, fontSize: 11)),
      const SizedBox(height: 4),
      Text(
        (p.label?.toString() ?? 'pending').toUpperCase(),
        style: TextStyle(
            color: _statusColor(p.label?.toString()),
            fontSize: 10,
            fontWeight: FontWeight.bold),
      ),
    ]);
  }

  // ═══ HELPERS ═══
  static const _statLabels = [
    'Speed',
    'Endurance',
    'Distance',
    'Dribbles',
    'Shots',
    'Heart Rate'
  ];

  List<double> _getPlayerStats(AiPlayer p) {
    final maxVals = [40.0, 100.0, 15.0, 20.0, 15.0, 200.0];
    final raw = [
      (p.speed).toDouble(),
      (p.endurance).toDouble(),
      (p.distance).toDouble(),
      (p.dribbles).toDouble(),
      (p.shots).toDouble(),
      (p.heartRate).toDouble(),
    ];
    return List.generate(
        raw.length, (i) => (raw[i] / maxVals[i]).clamp(0.0, 1.0));
  }

  Map<String, double> _getPlayerStatsMap(AiPlayer p) => {
        'Speed': p.speed.toDouble(),
        'Endurance': p.endurance.toDouble(),
        'Distance': p.distance.toDouble(),
        'Dribbles': p.dribbles.toDouble(),
        'Shots': p.shots.toDouble(),
        'Injuries': p.injuries.toDouble(),
        'Heart Rate': p.heartRate.toDouble(),
      };

  Widget _glassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AiColors.glassBackground,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AiColors.glassBorder),
          ),
          child: child,
        ),
      ),
    );
  }

  Color _statusColor(String? s) {
    switch (s?.toLowerCase()) {
      case 'recruited':
        return AiColors.success;
      case 'skipped':
        return AiColors.error;
      default:
        return AiColors.warning;
    }
  }
}

// ═══ RADAR CHART PAINTER ═══
class _RadarChartPainter extends CustomPainter {
  final List<double> playerA; // normalized 0‑1
  final List<double> playerB;
  final List<String> labels;

  _RadarChartPainter({
    required this.playerA,
    required this.playerB,
    required this.labels,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 30;
    final n = labels.length;
    final angleStep = 2 * pi / n;

    // Draw grid rings
    for (var ring = 1; ring <= 4; ring++) {
      final r = radius * ring / 4;
      final path = Path();
      for (var i = 0; i < n; i++) {
        final angle = -pi / 2 + angleStep * i;
        final x = center.dx + r * cos(angle);
        final y = center.dy + r * sin(angle);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.white.withOpacity(0.06)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }

    // Draw axis lines
    for (var i = 0; i < n; i++) {
      final angle = -pi / 2 + angleStep * i;
      final end = Offset(
          center.dx + radius * cos(angle),
          center.dy + radius * sin(angle));
      canvas.drawLine(
        center,
        end,
        Paint()
          ..color = Colors.white.withOpacity(0.08)
          ..strokeWidth = 1,
      );
    }

    // Draw labels
    final textStyle = TextStyle(
        color: Colors.white.withOpacity(0.5), fontSize: 10);
    for (var i = 0; i < n; i++) {
      final angle = -pi / 2 + angleStep * i;
      final labelRadius = radius + 18;
      final x = center.dx + labelRadius * cos(angle);
      final y = center.dy + labelRadius * sin(angle);
      final tp = TextPainter(
        text: TextSpan(text: labels[i], style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas,
          Offset(x - tp.width / 2, y - tp.height / 2));
    }

    // Draw player A polygon
    _drawPolygon(canvas, center, radius, playerA, n, angleStep,
        AiColors.primary);

    // Draw player B polygon
    _drawPolygon(canvas, center, radius, playerB, n, angleStep,
        AiColors.info);
  }

  void _drawPolygon(Canvas canvas, Offset center, double radius,
      List<double> values, int n, double angleStep, Color color) {
    final path = Path();
    for (var i = 0; i < n; i++) {
      final v = (i < values.length ? values[i] : 0.0).clamp(0.0, 1.0);
      final angle = -pi / 2 + angleStep * i;
      final r = radius * v;
      final x = center.dx + r * cos(angle);
      final y = center.dy + r * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    canvas.drawPath(
      path,
      Paint()
        ..color = color.withOpacity(0.15)
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // dots
    for (var i = 0; i < n; i++) {
      final v = (i < values.length ? values[i] : 0.0).clamp(0.0, 1.0);
      final angle = -pi / 2 + angleStep * i;
      final r = radius * v;
      canvas.drawCircle(
        Offset(center.dx + r * cos(angle),
            center.dy + r * sin(angle)),
        3,
        Paint()..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
