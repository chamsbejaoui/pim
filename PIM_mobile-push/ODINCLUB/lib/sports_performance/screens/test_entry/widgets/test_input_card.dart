import 'package:flutter/material.dart';
import '../../../models/test_type.dart';
import '../../../theme/sp_colors.dart';
import '../../../theme/sp_typography.dart';

class TestInputCard extends StatefulWidget {
  final TestType testType;
  final double? initialValue;
  final ValueChanged<double> onChanged;

  const TestInputCard({
    super.key,
    required this.testType,
    this.initialValue,
    required this.onChanged,
  });

  @override
  State<TestInputCard> createState() => _TestInputCardState();
}

class _TestInputCardState extends State<TestInputCard> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initialValue?.toString() ?? '',
    );
  }
  
  @override
  void didUpdateWidget(TestInputCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue && 
        widget.initialValue != null &&
        _controller.text.isEmpty) {
       _controller.text = widget.initialValue.toString();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SPColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SPColors.borderPrimary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.testType.name.toUpperCase(),
                style: SPTypography.label.copyWith(color: SPColors.textSecondary),
              ),
              if (widget.initialValue != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: SPColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'LAST: ${widget.initialValue} ${widget.testType.unit}',
                    style: SPTypography.overline.copyWith(color: SPColors.success),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: SPColors.backgroundPrimary,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: SPColors.borderPrimary),
                  ),
                  child: TextField(
                    controller: _controller,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: SPTypography.h2.copyWith(color: SPColors.textPrimary),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: '0.00',
                      hintStyle: TextStyle(color: SPColors.textTertiary.withOpacity(0.3)),
                      filled: false,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                    onChanged: (value) {
                      final doubleVal = double.tryParse(value);
                      if (doubleVal != null) {
                        widget.onChanged(doubleVal);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                widget.testType.unit,
                style: SPTypography.h5.copyWith(color: SPColors.textTertiary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
