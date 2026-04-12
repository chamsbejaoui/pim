import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/ai_colors.dart';
import '../../providers/campaign_provider.dart';

/// Real-time model performance: accuracy, F1, recall,
/// feature importance chart, AI online status.
class AiInsightsTab extends StatefulWidget {
  const AiInsightsTab({super.key});

  @override
  State<AiInsightsTab> createState() => _AiInsightsTabState();
}

class _AiInsightsTabState extends State<AiInsightsTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CampaignProvider>().loadAiMetrics();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CampaignProvider>(
      builder: (context, provider, _) {
        final metrics = provider.aiMetrics;
        final cv = metrics['cross_validation'] as Map<String, dynamic>? ?? {};
        final importances =
            metrics['feature_importance'] as Map<String, dynamic>? ?? {};

        final accuracy = cv['cv_accuracy']?.toString() ?? 'N/A';
        final f1 = cv['cv_f1']?.toString() ?? 'N/A';
        final recall = cv['cv_recall']?.toString() ?? 'N/A';

        double maxImp = 0;
        if (importances.isNotEmpty) {
          maxImp = importances.values
              .map((e) => (e as num).toDouble())
              .reduce((a, b) => a > b ? a : b);
        }

        final sortedFeatures = importances.entries.toList()
          ..sort((a, b) => (b.value as num).compareTo(a.value as num));

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
          children: [
            _buildStatusCard(provider.aiOnline),
            const SizedBox(height: 16),
            const Text('Model Performance (Real-time)',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            const SizedBox(height: 12),
            if (metrics.isEmpty && provider.aiOnline)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                    'No metrics yet. Train the model to see performance data.',
                    style:
                        TextStyle(color: Colors.white.withOpacity(0.7))),
              ),
            Row(children: [
              Expanded(
                  child: _buildMetricCard('Accuracy',
                      accuracy != 'N/A' ? '$accuracy%' : 'N/A',
                      Icons.check_circle_outline, AiColors.success)),
              const SizedBox(width: 12),
              Expanded(
                  child: _buildMetricCard(
                      'F1 Score',
                      f1 != 'N/A' ? '$f1%' : 'N/A',
                      Icons.analytics,
                      AiColors.primary)),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                  child: _buildMetricCard(
                      'Recall',
                      recall != 'N/A' ? '$recall%' : 'N/A',
                      Icons.radar,
                      AiColors.info)),
              const SizedBox(width: 12),
              Expanded(
                  child: _buildMetricCard(
                      'Training Set',
                      metrics['training_samples']?.toString() ?? '0',
                      Icons.storage,
                      AiColors.warning)),
            ]),
            const SizedBox(height: 24),
            if (importances.isNotEmpty) ...[
              const Text('Top Feature Importance',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              const SizedBox(height: 12),
              ...sortedFeatures.take(7).map((e) {
                final val = (e.value as num).toDouble();
                final pct = maxImp > 0 ? val / maxImp : 0.0;
                return _buildFeatureBar(e.key.toUpperCase(), pct,
                    _getColorForFeature(e.key));
              }),
              const SizedBox(height: 24),
            ],
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  AiColors.primary.withOpacity(0.2),
                  AiColors.primary.withOpacity(0.05),
                ]),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: AiColors.primary.withOpacity(0.3)),
              ),
              child: Column(children: [
                const Icon(Icons.psychology,
                    color: AiColors.primary, size: 40),
                const SizedBox(height: 12),
                const Text('Quick Predict',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                const SizedBox(height: 4),
                Text('Run AI prediction on selected players',
                    style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.6))),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: provider.aiOnline && !provider.isLoading
                          ? () => provider.loadPlayers()
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AiColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: provider.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Text('Run Prediction'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: provider.aiOnline && !provider.isLoading
                          ? () => _showTrainDialog(context, provider)
                          : null,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                            color: AiColors.primary.withOpacity(0.5)),
                      ),
                      child: const Text('Retrain Model'),
                    ),
                  ),
                ]),
              ]),
            ),
          ],
        );
      },
    );
  }

  void _showTrainDialog(BuildContext context, CampaignProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AiColors.backgroundDark,
        title: const Text('Retrain AI Model',
            style: TextStyle(color: Colors.white)),
        content: const Text(
            'This will send all labeled players to the AI engine to improve accuracy. Proceed?',
            style: TextStyle(color: AiColors.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              provider.trainModel();
            },
            child: const Text('Train Now'),
          ),
        ],
      ),
    );
  }

  Color _getColorForFeature(String feature) {
    switch (feature.toLowerCase()) {
      case 'speed':
        return AiColors.primary;
      case 'endurance':
        return AiColors.success;
      case 'dribbles':
        return AiColors.primaryLight;
      case 'shots':
        return AiColors.info;
      case 'injuries':
        return AiColors.error;
      case 'heart_rate':
        return AiColors.textSecondary;
      default:
        return AiColors.warning;
    }
  }

  Widget _buildStatusCard(bool isOnline) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AiColors.glassBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AiColors.glassBorder),
          ),
          child: Row(children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isOnline ? AiColors.success : AiColors.error,
                boxShadow: [
                  BoxShadow(
                      color: (isOnline ? AiColors.success : AiColors.error)
                          .withOpacity(0.4),
                      blurRadius: 8),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(isOnline ? 'AI Model Online' : 'AI Model Offline',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.white)),
            const Spacer(),
            Text(isOnline ? 'Connected' : 'No Connection',
                style: TextStyle(
                    fontSize: 12,
                    color: isOnline ? AiColors.success : AiColors.error,
                    fontWeight: FontWeight.w600)),
          ]),
        ),
      ),
    );
  }

  Widget _buildMetricCard(
      String label, String value, IconData icon, Color color) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AiColors.glassBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AiColors.glassBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 12),
              Text(value,
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              const SizedBox(height: 2),
              Text(label,
                  style: const TextStyle(
                      fontSize: 12, color: AiColors.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureBar(String label, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AiColors.textMuted)),
              Text('${(value * 100).round()}%',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: color)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value,
              backgroundColor: Colors.white.withOpacity(0.08),
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}
