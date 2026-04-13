import 'package:flutter/material.dart';

import '../services/finance_ai_service.dart';
import '../services/finance_store.dart';
import '../theme/finance_theme.dart';
import '../widgets/finance_widgets.dart';

class AiFinanceScreen extends StatefulWidget {
  const AiFinanceScreen({super.key});

  @override
  State<AiFinanceScreen> createState() => _AiFinanceScreenState();
}

class _AiFinanceScreenState extends State<AiFinanceScreen> {
  bool _loading = true;
  String? _error;
  FinanceAiBundle? _remoteBundle;

  @override
  void initState() {
    super.initState();
    _loadAiInsights();
  }

  Future<void> _loadAiInsights() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final store = FinanceStore.instance;
    try {
      await Future.delayed(const Duration(seconds: 2));
      final bundle = await FinanceAiService.instance.loadRemoteInsights(store);
      if (!mounted) return;
      setState(() {
        _remoteBundle = bundle;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = FinanceStore.instance;

    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        if (_loading && _remoteBundle == null) {
          return _AiThinkingView(onRefresh: _loadAiInsights);
        }

        final bundle = _remoteBundle;
        final forecastData = bundle?.forecastData ?? {};
        final cashflowData = bundle?.cashflowData ?? {};
        final impactData = bundle?.impactData ?? {};

        double numVal(dynamic value) {
          if (value is num) return value.toDouble();
          return double.tryParse(value?.toString() ?? '') ?? 0.0;
        }

        final nextSeason = (forecastData['nextSeason'] as Map<String, dynamic>?) ?? {};
        final seasonLabel = nextSeason['season']?.toString() ?? '—';
        final revenue = numVal(nextSeason['revenue']);
        final expense = numVal(nextSeason['expense']);
        final net = numVal(nextSeason['net']);
        final confidence = forecastData['confidence']?.toString() ?? '—';

        final cashLevel = cashflowData['level']?.toString() ?? 'LOW';
        final cashScore = cashflowData['score']?.toString() ?? '0';
        final projected = numVal(cashflowData['projectedCash']);
        final outflows = numVal(cashflowData['upcomingOutflows']);
        final notes = (cashflowData['notes'] as List? ?? [])
            .map((n) => n.toString())
            .toList();

        final sponsorPlus = numVal(impactData['sponsorPlus10']);
        final sponsorMinus = numVal(impactData['sponsorMinus10']);
        final transferNet = numVal(impactData['transferNet']);

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 104),
          children: [
            _ResultsHeader(
              generationTimeMs: bundle?.generationTimeMs,
              sourceLabel: bundle?.source ?? 'finance-ml',
            ),
            const SizedBox(height: 14),
            _ForecastCard(
              seasonLabel: seasonLabel,
              revenue: revenue,
              expense: expense,
              net: net,
              confidence: confidence,
            ),
            const SizedBox(height: 14),
            _CashflowCard(
              level: cashLevel,
              score: cashScore,
              projected: projected,
              outflows: outflows,
              notes: notes,
            ),
            const SizedBox(height: 14),
            _ImpactCard(
              sponsorPlus: sponsorPlus,
              sponsorMinus: sponsorMinus,
              transferNet: transferNet,
            ),
            if (_error != null) ...[
              const SizedBox(height: 14),
              _InfoPill(
                text: 'AI endpoint indisponible. Fallback local utilisé.',
                icon: Icons.warning_amber_rounded,
                tint: FinancePalette.danger,
              ),
            ],
          ],
        );
      },
    );
  }

  Future<void> _openAiDetailsSheet(
    BuildContext context,
    FinanceAiInsight insight,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${insight.title} (AI • ${insight.source.toUpperCase()})',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    insight.details,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ShortcutChip extends StatelessWidget {
  const _ShortcutChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: FinancePalette.soft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: FinancePalette.soft),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: FinancePalette.ink,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _AiFinanceHero extends StatelessWidget {
  const _AiFinanceHero({
    required this.loading,
    required this.sourceLabel,
    this.onRefresh,
  });

  final bool loading;
  final String sourceLabel;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            FinancePalette.blue.withValues(alpha: 0.30),
            FinancePalette.cyan.withValues(alpha: 0.18),
          ],
        ),
        border: Border.all(color: FinancePalette.blue.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: FinancePalette.blue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.psychology_alt_rounded, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'AI Finance',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              _InfoPill(
                text: loading ? 'Loading...' : sourceLabel,
                icon: Icons.bolt_rounded,
                tint: FinancePalette.success,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Prévisions intelligentes et actions d’optimisation pour le profil FINANCIER.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: FinancePalette.muted,
                  height: 1.4,
                ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onRefresh,
            icon: const Icon(Icons.auto_awesome_rounded),
            label: const Text('Rafraîchir IA'),
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.text,
    required this.icon,
    required this.tint,
  });

  final String text;
  final IconData icon;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tint.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: tint),
          const SizedBox(width: 6),
          Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: tint,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.title,
    required this.message,
    required this.icon,
    required this.accent,
    required this.source,
    this.onTap,
  });

  final String title;
  final String message;
  final IconData icon;
  final Color accent;
  final String source;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: FinancePalette.card,
          border: Border.all(color: FinancePalette.soft.withValues(alpha: 0.6)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 16,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: FinancePalette.muted,
                        ),
                  ),
                  const SizedBox(height: 8),
                  _InfoPill(
                    text: source.toUpperCase(),
                    icon: Icons.memory_rounded,
                    tint: accent,
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: accent),
          ],
        ),
      ),
    );
  }
}

class _AiThinkingView extends StatelessWidget {
  const _AiThinkingView({this.onRefresh});

  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 104),
      children: [
        _FloatingCard(
          child: Column(
            children: [
              Container(
                width: 78,
                height: 78,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: FinancePalette.cyan.withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: FinancePalette.cyan.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.psychology_alt_rounded,
                      color: FinancePalette.cyan,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _InfoPill(
                text: 'LIVE PROCESS',
                icon: Icons.bolt_rounded,
                tint: FinancePalette.cyan,
              ),
              const SizedBox(height: 12),
              Text(
                'AI Finance',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'Analyse en cours...',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: FinancePalette.muted,
                    ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _Bar(height: 12),
                  _Bar(height: 20),
                  _Bar(height: 30),
                  _Bar(height: 22),
                  _Bar(height: 14),
                ],
              ),
              const SizedBox(height: 12),
              if (onRefresh != null)
                FilledButton.icon(
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Relancer'),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _FloatingCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StepRow(
                label: 'Collecting ledger entries...',
                status: StepStatus.done,
              ),
              const SizedBox(height: 12),
              _StepRow(
                label: 'Analyzing payroll + transfers...',
                status: StepStatus.active,
              ),
              const SizedBox(height: 12),
              _StepRow(
                label: 'Generating forecast...',
                status: StepStatus.pending,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    'Estimated time: 1.2s',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: FinancePalette.muted,
                        ),
                  ),
                  const Spacer(),
                  Icon(Icons.more_horiz, color: FinancePalette.muted),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _FloatingCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: FinancePalette.cyan.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.lightbulb, color: FinancePalette.cyan),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'We use real club financial data to generate forecasts, risk alerts, and sponsor impact.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: FinancePalette.ink,
                        height: 1.4,
                      ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ResultsHeader extends StatelessWidget {
  const _ResultsHeader({
    required this.generationTimeMs,
    required this.sourceLabel,
  });

  final int? generationTimeMs;
  final String sourceLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: FinancePalette.cyan,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'ENGINE ACTIVE',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: FinancePalette.cyan,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
            ),
            const Spacer(),
            _InfoPill(
              text: sourceLabel.toUpperCase(),
              icon: Icons.memory_rounded,
              tint: FinancePalette.blue,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Finance AI Results',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        if (generationTimeMs != null) ...[
          const SizedBox(height: 4),
          Text(
            'Generated in ${generationTimeMs} ms',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: FinancePalette.muted,
                ),
          ),
        ],
      ],
    );
  }
}

class _ForecastCard extends StatelessWidget {
  const _ForecastCard({
    required this.seasonLabel,
    required this.revenue,
    required this.expense,
    required this.net,
    required this.confidence,
  });

  final String seasonLabel;
  final double revenue;
  final double expense;
  final double net;
  final String confidence;

  @override
  Widget build(BuildContext context) {
    return _FloatingCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _IconBadge(icon: Icons.show_chart_rounded),
              const SizedBox(width: 10),
              _Tag(text: 'DATA-DRIVEN AI', color: FinancePalette.cyan),
              const Spacer(),
              Text(
                'CONFIDENCE $confidence%',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: FinancePalette.muted,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Season Forecast $seasonLabel',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 14),
          _MetricRow(
            label: 'Revenue',
            value: formatCompactMoney(revenue, symbol: 'DT'),
          ),
          const SizedBox(height: 8),
          _MetricRow(
            label: 'Expenses',
            value: formatCompactMoney(expense, symbol: 'DT'),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: FinancePalette.soft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Net impact ${net >= 0 ? '+' : ''}${formatCompactMoney(net, symbol: 'DT')}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: FinancePalette.ink,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CashflowCard extends StatelessWidget {
  const _CashflowCard({
    required this.level,
    required this.score,
    required this.projected,
    required this.outflows,
    required this.notes,
  });

  final String level;
  final String score;
  final double projected;
  final double outflows;
  final List<String> notes;

  @override
  Widget build(BuildContext context) {
    return _FloatingCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _IconBadge(icon: Icons.warning_amber_rounded),
              const SizedBox(width: 10),
              _Tag(text: 'DATA-DRIVEN AI', color: FinancePalette.cyan),
              const Spacer(),
              _RiskPill(level: level),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Cash-flow Risk',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _MetricRow(label: 'Risk score', value: score),
              const SizedBox(width: 24),
              _MetricRow(
                label: 'Projected',
                value: formatCompactMoney(projected, symbol: 'DT'),
              ),
              const SizedBox(width: 24),
              _MetricRow(
                label: 'Outflows',
                value: formatCompactMoney(outflows, symbol: 'DT'),
                highlight: FinancePalette.danger,
              ),
            ],
          ),
          if (notes.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Analysis notes',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: FinancePalette.muted,
                  ),
            ),
            const SizedBox(height: 6),
            ...notes.map(
              (n) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• ',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: FinancePalette.cyan,
                            )),
                    Expanded(
                      child: Text(
                        n,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: FinancePalette.muted,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ImpactCard extends StatelessWidget {
  const _ImpactCard({
    required this.sponsorPlus,
    required this.sponsorMinus,
    required this.transferNet,
  });

  final double sponsorPlus;
  final double sponsorMinus;
  final double transferNet;

  @override
  Widget build(BuildContext context) {
    return _FloatingCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _IconBadge(icon: Icons.swap_horiz_rounded),
              const SizedBox(width: 10),
              _Tag(text: 'DATA-DRIVEN AI', color: FinancePalette.cyan),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Sponsor & Transfer Impact',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 12),
          _MetricRow(
            label: 'Sponsors +10%',
            value: '+${formatCompactMoney(sponsorPlus, symbol: 'DT')}',
            highlight: FinancePalette.success,
          ),
          const SizedBox(height: 8),
          _MetricRow(
            label: 'Sponsors -10%',
            value: '-${formatCompactMoney(sponsorMinus, symbol: 'DT')}',
            highlight: FinancePalette.danger,
          ),
          const SizedBox(height: 8),
          _MetricRow(
            label: 'Net transfers',
            value:
                '${transferNet >= 0 ? '+' : ''}${formatCompactMoney(transferNet, symbol: 'DT')}',
          ),
        ],
      ),
    );
  }
}

class _FloatingCard extends StatelessWidget {
  const _FloatingCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FinancePalette.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: FinancePalette.soft.withValues(alpha: 0.55)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: height,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: FinancePalette.cyan.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

enum StepStatus { done, active, pending }

class _StepRow extends StatelessWidget {
  const _StepRow({required this.label, required this.status});

  final String label;
  final StepStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      StepStatus.done => FinancePalette.cyan,
      StepStatus.active => FinancePalette.blue,
      StepStatus.pending => FinancePalette.muted,
    };

    Widget leading;
    if (status == StepStatus.done) {
      leading = Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.check_rounded, size: 16, color: color),
      );
    } else {
      leading = Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 2),
          shape: BoxShape.circle,
        ),
      );
    }

    return Row(
      children: [
        leading,
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: status == StepStatus.pending
                      ? FinancePalette.muted
                      : FinancePalette.ink,
                ),
          ),
        ),
      ],
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: FinancePalette.soft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: FinancePalette.cyan),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({
    required this.label,
    required this.value,
    this.highlight,
  });

  final String label;
  final String value;
  final Color? highlight;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: FinancePalette.muted,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: highlight ?? FinancePalette.ink,
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}

class _RiskPill extends StatelessWidget {
  const _RiskPill({required this.level});

  final String level;

  @override
  Widget build(BuildContext context) {
    Color color = FinancePalette.success;
    if (level.toUpperCase() == 'MEDIUM') {
      color = FinancePalette.warning;
    } else if (level.toUpperCase() == 'HIGH') {
      color = FinancePalette.danger;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        level.toUpperCase(),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
