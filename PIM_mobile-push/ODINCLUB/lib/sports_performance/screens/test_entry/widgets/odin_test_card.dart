import 'package:flutter/material.dart';
import '../../../models/test_type.dart';
import '../../../theme/sp_colors.dart';
import '../../../theme/sp_typography.dart';

class OdinTestCard extends StatefulWidget {
  final TestType testType;
  final double? initialValue;
  final ValueChanged<double> onChanged;
  final double min;
  final double max;
  final bool lowerIsBetter;

  const OdinTestCard({
    super.key,
    required this.testType,
    this.initialValue,
    required this.onChanged,
    this.min = 0,
    this.max = 100,
    this.lowerIsBetter = false,
  });

  @override
  State<OdinTestCard> createState() => _OdinTestCardState();
}

class _OdinTestCardState extends State<OdinTestCard> {
  late double _currentValue;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.initialValue ?? widget.min;
    // Clamp initial value to range
    if (_currentValue < widget.min) _currentValue = widget.min;
    if (_currentValue > widget.max) _currentValue = widget.max;
  }

  @override
  void didUpdateWidget(OdinTestCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue && widget.initialValue != null) {
      setState(() {
        _currentValue = widget.initialValue!;
      });
    }
  }

  Color _getScoreColor() {
    // Calculate normalized score 0-1
    double normalized = (_currentValue - widget.min) / (widget.max - widget.min);
    if (widget.lowerIsBetter) {
      normalized = 1 - normalized;
    }

    if (normalized < 0.4) return SPColors.error;
    if (normalized < 0.7) return SPColors.warning;
    return SPColors.success;
  }

  String _getRatingText() {
    double normalized = (_currentValue - widget.min) / (widget.max - widget.min);
    if (widget.lowerIsBetter) normalized = 1 - normalized;

    if (normalized < 0.2) return 'POOR';
    if (normalized < 0.4) return 'FAIR';
    if (normalized < 0.6) return 'GOOD';
    if (normalized < 0.8) return 'EXCELLENT';
    return 'ELITE';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: SPColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: SPColors.primaryBlue.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.testType.name.toUpperCase(),
                    style: SPTypography.caption.copyWith(
                      color: SPColors.textTertiary,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.testType.categoryLabel,
                    style: SPTypography.overline.copyWith(
                      color: SPColors.primaryBlue.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _getScoreColor().withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _getScoreColor().withValues(alpha: 0.3)),
                ),
                child: Text(
                  _getRatingText(),
                  style: SPTypography.overline.copyWith(
                    color: _getScoreColor(),
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _currentValue.toStringAsFixed(widget.testType.unit == '%' || widget.max > 20 ? 0 : 2),
                style: SPTypography.h1.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 42,
                  height: 1,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  widget.testType.unit,
                  style: SPTypography.h4.copyWith(
                    color: SPColors.textTertiary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 6,
              activeTrackColor: SPColors.primaryBlue,
              inactiveTrackColor: SPColors.backgroundTertiary,
              thumbColor: Colors.white,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
              overlayColor: SPColors.primaryBlue.withValues(alpha: 0.2),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 24),
            ),
            child: Slider(
              value: _currentValue,
              min: widget.min,
              max: widget.max,
              onChanged: (value) {
                setState(() {
                  _currentValue = value;
                });
                widget.onChanged(value);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.min.toInt().toString(),
                  style: SPTypography.overline.copyWith(color: SPColors.textTertiary),
                ),
                Text(
                  widget.max.toInt().toString(),
                  style: SPTypography.overline.copyWith(color: SPColors.textTertiary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
