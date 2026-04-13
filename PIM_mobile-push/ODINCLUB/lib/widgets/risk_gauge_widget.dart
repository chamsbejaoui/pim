import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../ui/theme/medical_theme.dart';

class RiskGaugeWidget extends StatelessWidget {
  const RiskGaugeWidget({
    super.key,
    required this.risk,
    this.label = 'Injury Risk',
  });

  final double risk;
  final String label;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxSize = constraints.maxWidth.isFinite
            ? math.min(constraints.maxWidth, 260.0)
            : 220.0;
        final size = math.max(200.0, maxSize).toDouble();

        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: risk.clamp(0.0, 1.0)),
          duration: const Duration(milliseconds: 1000),
          curve: Curves.easeOut,
          builder: (context, value, child) {
            return SizedBox(
              width: size,
              height: size,
              child: CustomPaint(
                painter: _RiskGaugePainter(
                  progress: value,
                  showGlow: risk >= 0.6,
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${(value * 100).toStringAsFixed(0)}%',
                        style:
                            textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: MedicalTheme.textPrimary,
                            ) ??
                            const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        label,
                        style:
                            textTheme.bodySmall?.copyWith(
                              color: MedicalTheme.textSecondary,
                            ) ??
                            const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _RiskGaugePainter extends CustomPainter {
  _RiskGaugePainter({required this.progress, required this.showGlow});

  final double progress;
  final bool showGlow;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width * 0.38;
    final basePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..color = MedicalTheme.cardBorder.withOpacity(0.35);

    canvas.drawCircle(center, radius, basePaint);

    final rect = Rect.fromCircle(center: center, radius: radius);
    final gradient = SweepGradient(
      colors: const [
        MedicalTheme.success,
        MedicalTheme.warning,
        MedicalTheme.danger,
      ],
      stops: const [0.0, 0.6, 1.0],
      startAngle: -math.pi / 2,
      endAngle: 3 * math.pi / 2,
    );

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..shader = gradient.createShader(rect);

    if (showGlow) {
      final glowPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 18
        ..strokeCap = StrokeCap.round
        ..shader = gradient.createShader(rect)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
      canvas.drawArc(
        rect,
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        glowPaint,
      );
    }

    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * progress, false, paint);
  }

  @override
  bool shouldRepaint(covariant _RiskGaugePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.showGlow != showGlow;
  }
}
