import 'dart:async';

import 'package:flutter/material.dart';

import '../models/alert_model.dart';
import '../services/alert_service.dart';
import '../ui/theme/medical_theme.dart';

class AlertOverlay extends StatefulWidget {
  AlertOverlay({super.key, AlertService? service})
    : service = service ?? AlertService.instance;

  final AlertService service;

  @override
  State<AlertOverlay> createState() => _AlertOverlayState();
}

class _AlertOverlayState extends State<AlertOverlay>
    with SingleTickerProviderStateMixin {
  OverlayEntry? _entry;
  AnimationController? _controller;
  Animation<Offset>? _slide;
  Animation<double>? _fade;
  StreamSubscription<AlertModel>? _subscription;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _subscription = widget.service.stream.listen(_show);
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _subscription?.cancel();
    _removeEntry(immediate: true);
    super.dispose();
  }

  void _show(AlertModel alert) {
    if (!mounted) {
      return;
    }

    if (!alert.notify) {
      return;
    }

    _dismissTimer?.cancel();
    _removeEntry(immediate: true);

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, -0.25),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller!, curve: Curves.easeOut));
    _fade = CurvedAnimation(parent: _controller!, curve: Curves.easeOut);

    _entry = OverlayEntry(
      builder: (context) => Positioned(
        top: 60,
        left: 16,
        right: 16,
        child: SafeArea(
          child: SlideTransition(
            position: _slide!,
            child: FadeTransition(
              opacity: _fade!,
              child: _AlertCard(alert: alert),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context, rootOverlay: true).insert(_entry!);
    _controller?.forward();

    _dismissTimer = Timer(const Duration(seconds: 3), () {
      _hide();
    });
  }

  Future<void> _hide() async {
    final controller = _controller;
    if (controller == null) {
      _removeEntry(immediate: true);
      return;
    }

    await controller.reverse();
    _removeEntry(immediate: true);
  }

  void _removeEntry({required bool immediate}) {
    _controller?.dispose();
    _controller = null;
    _slide = null;
    _fade = null;

    if (_entry != null) {
      _entry?.remove();
      _entry = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({required this.alert});

  final AlertModel alert;

  @override
  Widget build(BuildContext context) {
    final color = _accentColor(alert.status);
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: MedicalTheme.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.35)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.35),
              blurRadius: 16,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AlertIcon(status: alert.status, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alert.title,
                    style: textTheme.titleMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    alert.message,
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _statLine(alert),
                    style: textTheme.bodySmall?.copyWith(
                      color: MedicalTheme.textSecondary,
                    ),
                  ),
                  if (alert.reasons.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      alert.reasons.join(' • '),
                      style: textTheme.bodySmall?.copyWith(
                        color: MedicalTheme.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${(alert.risk * 100).toStringAsFixed(0)}%',
              style: textTheme.labelLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _statLine(AlertModel alert) {
    final parts = <String>[
      'Injury probability ${(alert.risk * 100).round()}%',
      'Load ${alert.load.round()}',
      'Fatigue ${alert.fatigue.round()}',
    ];
    if (alert.severity != null && alert.severity!.trim().isNotEmpty) {
      parts.add('Severity ${alert.severity}');
    }
    if (alert.recoveryDays != null && alert.recoveryDays! > 0) {
      parts.add('Recovery ${alert.recoveryDays}d');
    }
    if (alert.injuryType != null && alert.injuryType!.trim().isNotEmpty) {
      parts.add('Type ${alert.injuryType}');
    }
    return parts.join(' • ');
  }

  Color _accentColor(AlertStatus status) {
    switch (status) {
      case AlertStatus.injured:
        return MedicalTheme.danger;
      case AlertStatus.warning:
        return MedicalTheme.warning;
      case AlertStatus.safe:
        return MedicalTheme.success;
    }
  }
}

class _AlertIcon extends StatelessWidget {
  const _AlertIcon({required this.status, required this.color});

  final AlertStatus status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    IconData icon;
    switch (status) {
      case AlertStatus.injured:
        icon = Icons.warning_rounded;
        break;
      case AlertStatus.warning:
        icon = Icons.error_outline_rounded;
        break;
      case AlertStatus.safe:
        icon = Icons.check_circle_outline;
        break;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withOpacity(0.16),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }
}
