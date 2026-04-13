import 'package:flutter/material.dart';

import '../models/heatmap_model.dart';
import '../theme/app_theme.dart';

class InjuryHeatmapWidget extends StatelessWidget {
  const InjuryHeatmapWidget({
    super.key,
    required this.injuryType,
    required this.injuryProbability,
  });

  final String injuryType;
  final double injuryProbability;

  @override
  Widget build(BuildContext context) {
    final activeZones = _resolveZones(injuryType);
    final color = _colorForProbability(injuryProbability);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;

        return Stack(
          alignment: Alignment.center,
          children: [
            Image.asset(
              'assets/images/body.png',
              width: width,
              height: height,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Icon(
                Icons.accessibility_new,
                size: width * 0.55,
                color: AppTheme.textSecondary,
              ),
            ),
            for (final zone in _zones)
              _HeatmapZoneOverlay(
                zone: zone,
                active: activeZones.contains(zone.id),
                color: color,
              ),
          ],
        );
      },
    );
  }

  Color _colorForProbability(double probability) {
    if (probability < 0.3) {
      return AppTheme.success;
    }
    if (probability < 0.6) {
      return AppTheme.warning;
    }
    return AppTheme.danger;
  }

  Set<HeatmapZoneId> _resolveZones(String injuryType) {
    final lower = injuryType.toLowerCase();
    if (lower.contains('hamstring')) {
      return {HeatmapZoneId.hamstringLeft, HeatmapZoneId.hamstringRight};
    }
    if (lower.contains('ankle')) {
      return {HeatmapZoneId.ankleLeft, HeatmapZoneId.ankleRight};
    }
    if (lower.contains('knee') || lower.contains('ligament')) {
      return {HeatmapZoneId.kneeLeft, HeatmapZoneId.kneeRight};
    }
    if (lower.contains('muscle') || lower.contains('fatigue')) {
      return {
        HeatmapZoneId.hamstringLeft,
        HeatmapZoneId.hamstringRight,
        HeatmapZoneId.kneeLeft,
        HeatmapZoneId.kneeRight,
        HeatmapZoneId.ankleLeft,
        HeatmapZoneId.ankleRight,
      };
    }
    if (lower.contains('shoulder')) {
      return {HeatmapZoneId.shoulderLeft, HeatmapZoneId.shoulderRight};
    }
    if (lower.contains('head')) {
      return {HeatmapZoneId.head};
    }
    return {};
  }
}

class _HeatmapZoneOverlay extends StatelessWidget {
  const _HeatmapZoneOverlay({
    required this.zone,
    required this.active,
    required this.color,
  });

  final HeatmapZone zone;
  final bool active;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (!active) {
      return const SizedBox.shrink();
    }

    final glow = color == AppTheme.danger;

    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          return Positioned(
            left: zone.left * w,
            top: zone.top * h,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 500),
              opacity: 0.85,
              child: Container(
                width: zone.width * w,
                height: zone.height * h,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(40),
                  boxShadow: glow
                      ? [
                          BoxShadow(
                            color: color.withOpacity(0.6),
                            blurRadius: 22,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

const List<HeatmapZone> _zones = [
  HeatmapZone(
    id: HeatmapZoneId.head,
    left: 0.42,
    top: 0.05,
    width: 0.16,
    height: 0.1,
  ),
  HeatmapZone(
    id: HeatmapZoneId.shoulderLeft,
    left: 0.25,
    top: 0.18,
    width: 0.18,
    height: 0.08,
  ),
  HeatmapZone(
    id: HeatmapZoneId.shoulderRight,
    left: 0.57,
    top: 0.18,
    width: 0.18,
    height: 0.08,
  ),
  HeatmapZone(
    id: HeatmapZoneId.hamstringLeft,
    left: 0.38,
    top: 0.5,
    width: 0.1,
    height: 0.16,
  ),
  HeatmapZone(
    id: HeatmapZoneId.hamstringRight,
    left: 0.52,
    top: 0.5,
    width: 0.1,
    height: 0.16,
  ),
  HeatmapZone(
    id: HeatmapZoneId.kneeLeft,
    left: 0.39,
    top: 0.68,
    width: 0.08,
    height: 0.1,
  ),
  HeatmapZone(
    id: HeatmapZoneId.kneeRight,
    left: 0.53,
    top: 0.68,
    width: 0.08,
    height: 0.1,
  ),
  HeatmapZone(
    id: HeatmapZoneId.ankleLeft,
    left: 0.39,
    top: 0.84,
    width: 0.08,
    height: 0.09,
  ),
  HeatmapZone(
    id: HeatmapZoneId.ankleRight,
    left: 0.53,
    top: 0.84,
    width: 0.08,
    height: 0.09,
  ),
];
