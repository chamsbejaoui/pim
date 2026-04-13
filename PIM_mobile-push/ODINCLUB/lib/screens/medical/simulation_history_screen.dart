import 'package:flutter/material.dart';

import '../../models/simulation_match_history_model.dart';
import '../../services/simulation_history_service.dart';
import '../../theme/app_theme.dart';
import '../../ui/components/app_section_header.dart';
import '../../ui/theme/app_spacing.dart';

class SimulationHistoryScreen extends StatefulWidget {
  const SimulationHistoryScreen({super.key});

  @override
  State<SimulationHistoryScreen> createState() =>
      _SimulationHistoryScreenState();
}

class _SimulationHistoryScreenState extends State<SimulationHistoryScreen> {
  final SimulationHistoryService _historyService = SimulationHistoryService();
  late Future<List<SimulationMatchHistoryItem>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = _historyService.fetchHistory();
  }

  Future<void> _refresh() async {
    setState(() {
      _historyFuture = _historyService.fetchHistory();
    });
    await _historyFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(gradient: AppTheme.appGradient),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.s16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppSectionHeader(
                title: 'Match history',
                subtitle: 'Simulation medical match results',
                action: IconButton(
                  tooltip: 'Refresh',
                  onPressed: _refresh,
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ),
              const SizedBox(height: AppSpacing.s16),
              FutureBuilder<List<SimulationMatchHistoryItem>>(
                future: _historyFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Text(
                      'Unable to load match history.',
                      style: Theme.of(context).textTheme.bodySmall,
                    );
                  }
                  final items = snapshot.data ?? [];
                  if (items.isEmpty) {
                    return Text(
                      'No match history yet.',
                      style: Theme.of(context).textTheme.bodySmall,
                    );
                  }

                  return Column(
                    children: items
                        .map((item) => _HistoryCard(item: item))
                        .toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.item});

  final SimulationMatchHistoryItem item;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.s12),
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Match ${item.matchId.substring(0, 6).toUpperCase()}',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                _formatDate(item.endedAt),
                style: textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _StatChip(
                label: 'Injured',
                value: item.injuredCount.toString(),
                color: AppTheme.danger,
              ),
              _StatChip(
                label: 'Warning',
                value: item.warningCount.toString(),
                color: AppTheme.warning,
              ),
              _StatChip(
                label: 'Safe',
                value: item.safeCount.toString(),
                color: AppTheme.success,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  label: 'Score',
                  value: '${item.stats.homeScore}-${item.stats.awayScore}',
                ),
              ),
              Expanded(
                child: _MiniStat(
                  label: 'Possession',
                  value:
                      '${item.stats.possessionHome}%/${100 - item.stats.possessionHome}%',
                ),
              ),
              Expanded(
                child: _MiniStat(
                  label: 'Shots',
                  value: '${item.stats.shotsHome}/${item.stats.shotsAway}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  label: 'On target',
                  value:
                      '${item.stats.shotsOnTargetHome}/${item.stats.shotsOnTargetAway}',
                ),
              ),
              const Spacer(flex: 2),
            ],
          ),
          if (item.injuredPlayers.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Injured players',
              style: textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Column(
              children: item.injuredPlayers.map((player) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          player.name,
                          style: textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        '${(player.injuryProbability * 100).round()}%',
                        style: textTheme.bodySmall?.copyWith(
                          color: AppTheme.danger,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final h = date.hour.toString().padLeft(2, '0');
    final m = date.minute.toString().padLeft(2, '0');
    return '${date.day}/${date.month} $h:$m';
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(
        '$label $value',
        style: textTheme.labelMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
