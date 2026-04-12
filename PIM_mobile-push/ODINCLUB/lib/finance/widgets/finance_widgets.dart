import 'dart:async';

import 'package:flutter/material.dart';
import '../theme/finance_theme.dart';

String formatCompactMoney(double value, {String symbol = 'DT'}) {
  final abs = value.abs();
  String formatted;
  if (abs >= 1000000000) {
    formatted = '${(value / 1000000000).toStringAsFixed(1)}B';
  } else if (abs >= 1000000) {
    formatted = '${(value / 1000000).toStringAsFixed(1)}M';
  } else if (abs >= 1000) {
    formatted = '${(value / 1000).toStringAsFixed(1)}K';
  } else {
    formatted = value.toStringAsFixed(0);
  }
  if (symbol.isEmpty) return formatted;
  return '$formatted $symbol';
}

class GradientShell extends StatelessWidget {
  const GradientShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final top = FinancePalette.isDark
        ? FinancePalette.scaffold
        : const Color(0xFFEAF4FF);
    final bottom = FinancePalette.isDark
        ? const Color(0xFF090F36)
        : const Color(0xFFF7FAFF);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [top, bottom],
        ),
      ),
      child: child,
    );
  }
}

class FinanceCard extends StatelessWidget {
  const FinanceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 22,
  });

  final Widget child;
  final EdgeInsets padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: FinancePalette.card,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: FinancePalette.blue.withValues(alpha: 0.08),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: child,
    );
  }
}

class MetricTile extends StatelessWidget {
  const MetricTile({
    super.key,
    required this.label,
    required this.value,
    this.delta,
    this.positive = true,
    this.icon,
  });

  final String label;
  final String value;
  final String? delta;
  final bool positive;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return FinanceCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null)
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: FinancePalette.soft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 16, color: FinancePalette.blue),
                ),
              if (icon != null) const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: FinancePalette.ink.withValues(alpha: 0.55),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: Theme.of(context).textTheme.titleLarge),
          if (delta != null) ...[
            const SizedBox(height: 6),
            Text(
              delta!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: positive
                    ? FinancePalette.success
                    : FinancePalette.danger,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class SectionLabel extends StatelessWidget {
  const SectionLabel({super.key, required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        if (subtitle != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              subtitle!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: FinancePalette.ink.withValues(alpha: 0.58),
              ),
            ),
          ),
      ],
    );
  }
}

class AmountTag extends StatelessWidget {
  const AmountTag({super.key, required this.amount, required this.positive});

  final String amount;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    return Text(
      amount,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: positive ? FinancePalette.success : FinancePalette.danger,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class DelayedReveal extends StatefulWidget {
  const DelayedReveal({super.key, required this.child, required this.delay});

  final Widget child;
  final Duration delay;

  @override
  State<DelayedReveal> createState() => _DelayedRevealState();
}

class _DelayedRevealState extends State<DelayedReveal> {
  bool _visible = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.delay, () {
      if (mounted) {
        setState(() => _visible = true);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      offset: _visible ? Offset.zero : const Offset(0, 0.08),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 400),
        opacity: _visible ? 1 : 0,
        child: widget.child,
      ),
    );
  }
}
