import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/medical_result_model.dart';
import '../../models/player_model.dart';
import 'injury_heatmap_screen.dart';
import '../../services/medical_service.dart';
import '../../services/player_service.dart';
import '../../theme/app_theme.dart';
import '../../ui/components/app_section_header.dart';
import '../../ui/theme/app_colors.dart';
import '../../ui/theme/app_spacing.dart';
import '../../widgets/bullet_list_card.dart';
import '../../widgets/confidence_card.dart';
import '../../widgets/nutrition_card.dart';
import '../../widgets/risk_gauge_widget.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/warning_banner.dart';
import '../../services/nutrition_service.dart';

class MedicalAnalysisScreen extends StatefulWidget {
  const MedicalAnalysisScreen({super.key, required this.player});

  final PlayerModel player;

  @override
  State<MedicalAnalysisScreen> createState() => _MedicalAnalysisScreenState();
}

class _MedicalAnalysisScreenState extends State<MedicalAnalysisScreen>
    with SingleTickerProviderStateMixin {
  final MedicalService _medicalService = MedicalService();
  final PlayerService _playerService = PlayerService();

  bool _isLoading = false;
  MedicalResultModel? _result;
  String? _errorMessage;
  late final AnimationController _ballController;
  late PlayerModel _player;

  Future<void> _runAnalysis() async {
    final startedAt = DateTime.now();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _medicalService.analyze(
        playerId: _player.id,
        fatigue: 40,
        minutes: 60,
        load: 50,
      );

      PlayerModel? refreshedPlayer;
      try {
        refreshedPlayer = await _playerService.fetchPlayer(_player.id);
      } catch (_) {
        refreshedPlayer = null;
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _result = result;
        if (refreshedPlayer != null) {
          _player = refreshedPlayer;
        }
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = error.toString();
      });
    } finally {
      final elapsed = DateTime.now().difference(startedAt);
      const minVisible = Duration(milliseconds: 800);
      if (elapsed < minVisible) {
        await Future.delayed(minVisible - elapsed);
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _player = widget.player;
    _ballController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _ballController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final player = _player;

    return Container(
      decoration: BoxDecoration(gradient: AppTheme.appGradient),
      child: Stack(
        children: [
          DefaultTextStyle.merge(
            style: TextStyle(
              color: AppTheme.textPrimary,
              decoration: TextDecoration.none,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.s16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppSectionHeader(
                    title: 'Medical Analysis',
                    subtitle: player.name,
                    action: IconButton(
                      tooltip: 'Back',
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s16),
                  _PlayerHeader(player: player),
                  const SizedBox(height: AppSpacing.s16),
                  _ActionCard(isLoading: _isLoading, onRun: _runAnalysis),
                  if (_errorMessage != null && _errorMessage!.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.s12),
                    _InlineError(message: _errorMessage!),
                  ],
                  const SizedBox(height: AppSpacing.s16),
                  AnimatedOpacity(
                    opacity: _result == null ? 0 : 1,
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOut,
                    child: _result == null
                        ? const SizedBox.shrink()
                        : _ResultBody(result: _result!, player: player),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: AppTheme.background.withValues(alpha: 0.88),
                child: const Center(child: _LoadingOverlay()),
              ),
            ),
        ],
      ),
    );
  }
}

class _FootballHero extends StatelessWidget {
  const _FootballHero({required this.controller});

  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          final t = controller.value;
          final bob = math.sin(t * 2 * math.pi) * 6;
          final glow = 0.2 + (0.35 * t);
          final rotate = t * 2 * math.pi;

          return Transform.translate(
            offset: Offset(0, bob),
            child: SizedBox(
              width: 180,
              height: 180,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppTheme.accentBlue.withValues(alpha: 0.18),
                          AppTheme.background.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                  Transform.rotate(
                    angle: rotate,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.accentBlue.withValues(alpha: 0.25),
                          width: 1.4,
                        ),
                      ),
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: AppTheme.accentBlue,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.accentBlue.withValues(
                                  alpha: 0.6,
                                ),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.accentBlue.withValues(alpha: glow),
                          blurRadius: 26,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      backgroundColor: AppTheme.card,
                      child: Icon(
                        Icons.sports_soccer,
                        color: AppTheme.accentBlue,
                        size: 42,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 24,
                    child: Container(
                      width: 90,
                      height: 18,
                      decoration: BoxDecoration(
                        color: AppTheme.background.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.textPrimary.withValues(alpha: 0.35),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _LoadingOverlay extends StatefulWidget {
  const _LoadingOverlay();

  @override
  State<_LoadingOverlay> createState() => _LoadingOverlayState();
}

class _LoadingOverlayState extends State<_LoadingOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FootballHero(controller: _controller),
        const SizedBox(height: 16),
        Text(
          'Analyzing medical signals...',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: textTheme.titleMedium?.fontSize ?? 16,
            color: AppTheme.textPrimary,
            decoration: TextDecoration.none,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'AI engine running',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: textTheme.bodySmall?.fontSize ?? 12,
            decoration: TextDecoration.none,
          ),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.isLoading, required this.onRun});

  final bool isLoading;
  final VoidCallback onRun;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final stack = constraints.maxWidth < 360;
        final button = ElevatedButton(
          onPressed: isLoading ? null : onRun,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryBlue,
            foregroundColor: AppColors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: isLoading
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: AppColors.white,
                  ),
                )
              : Text('Run', style: TextStyle(fontWeight: FontWeight.w600)),
        );

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.cardBorder),
          ),
          child: stack
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Run Medical Analysis',
                      style: TextStyle(
                        fontSize: textTheme.titleLarge?.fontSize ?? 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Generate AI injury insights',
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(width: double.infinity, child: button),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Run Medical Analysis',
                            style: TextStyle(
                              fontSize: textTheme.titleLarge?.fontSize ?? 18,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Generate AI injury insights',
                            style: textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    button,
                  ],
                ),
        );
      },
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.danger.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.danger.withValues(alpha: 0.4)),
      ),
      child: Text(
        message,
        style: TextStyle(color: AppTheme.textPrimary, fontSize: 12),
      ),
    );
  }
}

class _ResultBody extends StatelessWidget {
  const _ResultBody({required this.result, required this.player});

  final MedicalResultModel result;
  final PlayerModel player;

  @override
  Widget build(BuildContext context) {
    final probability = (result.injuryProbability * 100)
        .clamp(0, 100)
        .toDouble();
    final confidence = (result.confidence * 100).clamp(0, 100).toDouble();
    final status = _normalizeStatus(result.status, result.injuryProbability);
    final isCurrentlyInjured = player.isInjured == true && !result.injured;
    final textTheme = Theme.of(context).textTheme;
    final nutritionPlan = NutritionService().buildPlan(
      result: result,
      player: player,
      fatigue: player.lastMatchFatigue ?? 40,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isCurrentlyInjured) ...[
          WarningBanner(
            message:
                'Player is currently injured from the latest match. Medical test results do not clear this status.',
          ),
          const SizedBox(height: 12),
        ],
        Text(
          'AI Risk Analysis',
          style:
              textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700) ??
              const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 20),
        Center(child: RiskGaugeWidget(risk: result.injuryProbability)),
        const SizedBox(height: 20),
        ConfidenceCard(confidence: confidence / 100),
        const SizedBox(height: 12),
        Center(child: StatusBadge(status: status)),
        const SizedBox(height: 16),
        _RiskLegend(),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => InjuryHeatmapScreen(
                    playerName: player.name,
                    result: result,
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.bubble_chart_outlined),
            label: const Text(
              'View Injury Heatmap',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (result.injured) ...[
          _SummaryCard(result: result, probability: probability),
          const SizedBox(height: 16),
          BulletListCard(
            title: 'Rehabilitation',
            items: result.rehabilitation,
            icon: Icons.fitness_center,
          ),
          const SizedBox(height: 12),
          BulletListCard(
            title: 'Prevention',
            items: result.prevention.isEmpty
                ? const ['Maintain balanced load and recovery routines.']
                : result.prevention,
            icon: Icons.shield,
          ),
          const SizedBox(height: 12),
          if (result.warning.trim().isNotEmpty)
            WarningBanner(message: result.warning),
        ] else ...[
          _HealthyStatusCard(probability: result.injuryProbability),
          const SizedBox(height: 16),
          BulletListCard(
            title: 'Prevention',
            items: result.prevention.isEmpty
                ? const ['Maintain balanced load and recovery routines.']
                : result.prevention,
            icon: Icons.shield,
          ),
          const SizedBox(height: 12),
          _HistoryStatCard(totalInjuries: player.injuryHistory),
        ],
        const SizedBox(height: 16),
        Text(
          'Nutrition Recommendation',
          style:
              textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700) ??
              const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        NutritionCard(plan: nutritionPlan),
      ],
    );
  }
}

class _PlayerHeader extends StatelessWidget {
  const _PlayerHeader({required this.player});

  final PlayerModel player;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isInjured = player.isInjured == true;
    final injuryLabel = (player.lastInjuryType ?? '').trim();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.health_and_safety,
              color: AppTheme.accentBlue,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.name,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  player.position,
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  'Base fitness: ${player.baseFitness}',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 140),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isInjured
                    ? AppTheme.danger.withOpacity(0.12)
                    : AppTheme.success.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isInjured
                    ? (injuryLabel.isEmpty
                          ? 'Injured'
                          : 'Injured • $injuryLabel')
                    : 'Available',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isInjured ? AppTheme.danger : AppTheme.success,
                  fontSize: textTheme.labelMedium?.fontSize ?? 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.result, required this.probability});

  final MedicalResultModel result;
  final double probability;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final severityColor = _severityColor(result.severity);
    final recoveryLabel = result.recoveryDays == 0
        ? 'TBD'
        : result.recoveryDays.toString();

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
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Medical Insight',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: severityColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  result.severity,
                  style: TextStyle(
                    color: severityColor,
                    fontWeight: FontWeight.w600,
                    fontSize: textTheme.labelLarge?.fontSize ?? 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            result.injuryType,
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            'Monitor recovery and adjust training load based on AI guidance.',
            style: textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _MetricTile(
                label: 'Probability',
                value: '${probability.toStringAsFixed(0)}%',
                accentColor: severityColor,
              ),
              const SizedBox(width: 12),
              _MetricTile(
                label: 'Recovery days',
                value: recoveryLabel,
                accentColor: AppTheme.accentBlue,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _severityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'severe':
        return AppTheme.danger;
      case 'moderate':
        return AppTheme.warning;
      case 'mild':
      default:
        return AppTheme.success;
    }
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.accentColor,
  });

  final String label;
  final String value;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceAlt,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: textTheme.labelMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                color: accentColor,
                fontSize: textTheme.titleMedium?.fontSize ?? 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HealthyStatusCard extends StatelessWidget {
  const _HealthyStatusCard({required this.probability});

  final double probability;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final display = (probability * 100).clamp(0, 100).toDouble();
    final riskLabel = display < 30
        ? 'LOW RISK'
        : display < 60
        ? 'MODERATE RISK'
        : 'HIGH RISK';

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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.success.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Healthy',
                  style: textTheme.labelLarge?.copyWith(
                    color: AppTheme.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                riskLabel,
                style: textTheme.labelMedium?.copyWith(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Player is in good condition.',
            style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Training load is within safe limits.',
            style: textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _HistoryStatCard extends StatelessWidget {
  const _HistoryStatCard({required this.totalInjuries});

  final int totalInjuries;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Injury history',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          Text(
            '$totalInjuries total',
            style: textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _RiskLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Legend',
          style:
              textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600) ??
              const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: const [
            _LegendItem(color: AppTheme.success, label: 'Low Risk (0-30%)'),
            _LegendItem(color: AppTheme.warning, label: 'Medium Risk (30-60%)'),
            _LegendItem(color: AppTheme.danger, label: 'High Risk (60-100%)'),
          ],
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: textTheme.bodySmall ?? const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}

String _normalizeStatus(String status, double risk) {
  final normalized = status.trim().toUpperCase();
  if (normalized == 'SAFE' ||
      normalized == 'WARNING' ||
      normalized == 'INJURED') {
    return normalized;
  }
  if (risk >= 0.6) {
    return 'INJURED';
  }
  if (risk >= 0.3) {
    return 'WARNING';
  }
  return 'SAFE';
}
