import 'dart:ui';
import 'package:flutter/material.dart';
import '../../theme/ai_colors.dart';
import '../../models/ai_player.dart';
import 'package:provider/provider.dart';
import '../../providers/campaign_provider.dart';
import 'ai_player_insights_screen.dart';

/// Single player detail view: stat bars, SHAP analysis, recruit/skip.
class AiPlayerDetailScreen extends StatelessWidget {
  final AiPlayer player;
  const AiPlayerDetailScreen({super.key, required this.player});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AiColors.backgroundDark,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AiColors.backgroundDark,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 18),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(player.name,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AiColors.primary.withOpacity(0.4),
                      AiColors.backgroundDark,
                    ],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 16),
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 38,
                            backgroundColor:
                                AiColors.primary.withOpacity(0.3),
                            child: Text(
                              player.name.isNotEmpty
                                  ? player.name[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: _matchColor(
                                  player.computedMatchPercentage.round()),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${player.computedMatchPercentage.round()}%',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(player.club ?? 'Unknown Club',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildInfoRow(),
                const SizedBox(height: 20),
                _buildStatsCard(),
                const SizedBox(height: 20),
                if (player.shapExplanation != null &&
                    player.shapExplanation!.isNotEmpty)
                  _buildShapCard(),
                if (player.aiRecommendation != null &&
                    player.aiRecommendation!.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _buildRecommendationCard(),
                ],
                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  Widget _buildInfoRow() {
    return Row(children: [
      _infoChip(Icons.cake, '${player.age ?? '-'} yrs'),
      const SizedBox(width: 8),
      _infoChip(Icons.sports_soccer, player.position ?? '-'),
      const SizedBox(width: 8),
      if (player.clusterProfile != null)
        _infoChip(Icons.hub, player.clusterProfile!),
      const Spacer(),
      Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: _statusColor(player.label?.toString() ?? player.status)
              .withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          (player.label?.toString() ?? player.status).toUpperCase(),
          style: TextStyle(
              color: _statusColor(player.label?.toString() ?? player.status),
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5),
        ),
      ),
    ]);
  }

  Widget _infoChip(IconData icon, String text) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AiColors.glassBackground,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AiColors.glassBorder),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon,
                size: 14,
                color: Colors.white.withOpacity(0.6)),
            const SizedBox(width: 4),
            Text(text,
                style: const TextStyle(
                    color: Colors.white, fontSize: 12)),
          ]),
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    final stats = <MapEntry<String, double>>[
      MapEntry('Speed', player.speed.toDouble()),
      MapEntry('Endurance', player.endurance.toDouble()),
      MapEntry('Distance', player.distance.toDouble()),
      MapEntry('Dribbles', player.dribbles.toDouble()),
      MapEntry('Shots', player.shots.toDouble()),
      MapEntry('Injuries', player.injuries.toDouble()),
      MapEntry('Heart Rate', player.heartRate.toDouble()),
    ];

    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.bar_chart, color: AiColors.primary, size: 20),
            SizedBox(width: 8),
            Text('Performance Stats',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AiColors.primary)),
          ]),
          const SizedBox(height: 14),
          ...stats.map((e) => _statBar(e.key, e.value)),
        ],
      ),
    );
  }

  Widget _statBar(String label, double value) {
    final maxValues = {
      'Speed': 40.0,
      'Endurance': 100.0,
      'Distance': 15.0,
      'Dribbles': 20.0,
      'Shots': 15.0,
      'Injuries': 10.0,
      'Heart Rate': 200.0,
    };
    final maxVal = maxValues[label] ?? 100.0;
    final ratio = (value / maxVal).clamp(0.0, 1.0);

    Color barColor;
    if (label == 'Injuries') {
      barColor = value > 5 ? AiColors.error : AiColors.success;
    } else if (label == 'Heart Rate') {
      barColor = (value > 80 && value < 180)
          ? AiColors.success
          : AiColors.warning;
    } else {
      barColor = ratio > 0.7
          ? AiColors.success
          : ratio > 0.4
              ? AiColors.info
              : AiColors.warning;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label.toUpperCase(),
                style: const TextStyle(
                    color: AiColors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5)),
            Text(value.toStringAsFixed(1),
                style: TextStyle(
                    color: barColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            backgroundColor: barColor.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation(barColor),
            minHeight: 6,
          ),
        ),
      ]),
    );
  }

  Widget _buildShapCard() {
    final shap = player.shapExplanation!;
    final entries = shap.entries.toList()
      ..sort((a, b) =>
          (b.value as num).abs().compareTo((a.value as num).abs()));

    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.psychology,
                color: AiColors.info, size: 20),
            SizedBox(width: 8),
            Text('AI Match Analysis (SHAP)',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AiColors.info)),
          ]),
          const SizedBox(height: 6),
          Text(
            'How each feature influences the recruitment decision',
            style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 11),
          ),
          const SizedBox(height: 14),
          ...entries.map((e) => _shapBar(e.key, e.value)),
        ],
      ),
    );
  }

  Widget _shapBar(String feature, dynamic value) {
    final val = (value as num).toDouble();
    final isPositive = val > 0;
    final absVal = val.abs();
    final maxShap = 1.0;
    final ratio = (absVal / maxShap).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        SizedBox(
          width: 90,
          child: Text(
            feature.replaceAll('_', ' ').toUpperCase(),
            style: const TextStyle(
                color: AiColors.textSecondary,
                fontSize: 9,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Row(children: [
            Expanded(
              child: isPositive
                  ? const SizedBox.shrink()
                  : Align(
                      alignment: Alignment.centerRight,
                      child: FractionallySizedBox(
                        widthFactor: ratio,
                        child: Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: AiColors.error,
                            borderRadius:
                                BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
            ),
            Container(
                width: 1,
                height: 16,
                color: Colors.white.withOpacity(0.2)),
            Expanded(
              child: isPositive
                  ? FractionallySizedBox(
                      widthFactor: ratio,
                      alignment: Alignment.centerLeft,
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: AiColors.success,
                          borderRadius:
                              BorderRadius.circular(4),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ]),
        ),
        const SizedBox(width: 6),
        SizedBox(
          width: 45,
          child: Text(
            val.toStringAsFixed(3),
            textAlign: TextAlign.end,
            style: TextStyle(
                color: isPositive ? AiColors.success : AiColors.error,
                fontSize: 10,
                fontWeight: FontWeight.w600),
          ),
        ),
      ]),
    );
  }

  Widget _buildRecommendationCard() {
    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.auto_awesome,
                color: AiColors.warning, size: 20),
            SizedBox(width: 8),
            Text('AI Recommendation',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AiColors.warning)),
          ]),
          const SizedBox(height: 12),
          Text(
            player.aiRecommendation!,
            style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 13,
                height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AiColors.backgroundDark,
        border:
            const Border(top: BorderSide(color: AiColors.borderDark)),
      ),
      child: Row(children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              context.read<CampaignProvider>().skipPlayer(player);
              Navigator.pop(context);
            },
            icon: const Icon(Icons.close),
            label: const Text('Skip'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: AiColors.borderDark),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      ChangeNotifierProvider.value(
                        value: context.read<CampaignProvider>(),
                        child: AiPlayerInsightsScreen(player: player),
                      ),
                ),
              );
            },
            icon: const Icon(Icons.insights),
            label: const Text('AI Insights'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AiColors.info,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              context
                  .read<CampaignProvider>()
                  .recruitPlayer(player);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('${player.name} Recruited!'),
                backgroundColor: AiColors.primary,
              ));
            },
            icon: const Icon(Icons.check),
            label: const Text('Recruit'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AiColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ]),
    );
  }

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

  Color _matchColor(int pct) {
    if (pct >= 80) return AiColors.success;
    if (pct >= 60) return AiColors.info;
    if (pct >= 40) return AiColors.warning;
    return AiColors.error;
  }

  Color _statusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'recruited':
        return AiColors.success;
      case 'skipped':
        return AiColors.error;
      case 'pending':
        return AiColors.warning;
      default:
        return AiColors.textSecondary;
    }
  }
}
