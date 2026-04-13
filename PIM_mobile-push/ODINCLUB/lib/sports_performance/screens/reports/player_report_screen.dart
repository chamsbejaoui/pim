import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/player_report.dart';
import '../../models/event_player.dart';
import '../../providers/reports_provider.dart';
import '../../theme/sp_colors.dart';
import '../../theme/sp_typography.dart';
import '../../widgets/performance_progression_chart.dart';
import '../../providers/reports_provider.dart';
import '../../../services/ai_scouting_bridge.dart';
import '../../../screens/ai/ai_campaign_screen.dart';
import 'package:provider/provider.dart' as prov;
import '../../../providers/campaign_provider.dart';
import '../exercises/generator_form.dart';

class PlayerReportScreen extends ConsumerWidget {
  final String eventPlayerId;

  const PlayerReportScreen({
    super.key,
    required this.eventPlayerId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(playerReportProvider(eventPlayerId));

    return reportAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error', style: const TextStyle(color: Colors.white))),
      data: (report) {
        final playerId = report.eventPlayer is String 
            ? report.eventPlayer 
            : (report.eventPlayer as EventPlayer).player.id;
        
        final progressionAsync = ref.watch(playerProgressionProvider(playerId));

        return Scaffold(
          backgroundColor: SPColors.backgroundPrimary,
      appBar: AppBar(
        title: Text(
          'RAPPORT JOUEUR',
          style: SPTypography.h4.copyWith(color: SPColors.textPrimary),
        ),
        backgroundColor: SPColors.backgroundPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: SPColors.textSecondary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: SPColors.primaryBlue),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildPlayerHeader(context, report),
                const SizedBox(height: 32),
                _buildGlowingScore(report),
                const SizedBox(height: 12),
                _buildPerformanceBadge(report),
                const SizedBox(height: 40),
                _buildRadarChartSection(report),
                const SizedBox(height: 32),
                
                // New Progression Section
                progressionAsync.when(
                  data: (data) => PerformanceProgressionChart(
                    tests: data['tests'] ?? [],
                    matches: data['matches'] ?? [],
                  ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, r) => const Text('Erreur historique progression'),
                ),
                
                const SizedBox(height: 32),
                _buildAISynthesis(context, report),
                const SizedBox(height: 20),
                _buildSendToAiButton(context, report),
                const SizedBox(height: 32),
                _buildDetailedMetrics(report),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlayerHeader(BuildContext context, PlayerReport report) {
    final player = report.eventPlayer is EventPlayer ? (report.eventPlayer as EventPlayer).player : null;
    final String fullName = player != null ? '${player.firstName} ${player.lastName}' : 'Unknown Player';
    final String position = player?.position ?? 'N/A';
    final String jerseyNumber = player?.jerseyNumber != null ? '#${player!.jerseyNumber}' : '';

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: SPColors.primaryBlue.withOpacity(0.5)),
          ),
          child: CircleAvatar(
            radius: 28,
            backgroundColor: SPColors.backgroundSecondary,
            backgroundImage: player?.photo != null ? NetworkImage(player!.photo!) : null,
            child: player?.photo == null ? const Icon(Icons.person, color: Colors.white) : null,
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              fullName,
              style: SPTypography.h4.copyWith(color: Colors.white),
            ),
            Row(
              children: [
                Text(
                  position,
                  style: SPTypography.bodySmall.copyWith(color: SPColors.primaryBlueLight),
                ),
                if (jerseyNumber.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Text(
                    '•',
                    style: TextStyle(color: SPColors.textTertiary),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    jerseyNumber,
                    style: SPTypography.bodySmall.copyWith(color: SPColors.textTertiary),
                  ),
                ],
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGlowingScore(PlayerReport report) {
    return Container(
      width: 180,
      height: 180,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: SPColors.primaryBlue.withOpacity(0.3),
            blurRadius: 40,
            spreadRadius: 10,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 160,
            height: 160,
            child: CircularProgressIndicator(
              value: report.overallScore / 100,
              strokeWidth: 10,
              backgroundColor: SPColors.backgroundSecondary,
              valueColor: const AlwaysStoppedAnimation<Color>(SPColors.primaryBlue),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                report.overallScore.toStringAsFixed(1),
                style: SPTypography.h1.copyWith(
                  color: Colors.white,
                  fontSize: 60,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'SCORE GLOBAL',
                style: SPTypography.overline.copyWith(
                  color: SPColors.textTertiary,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceBadge(PlayerReport report) {
    String level = 'ZONE DE PERFORMANCE ÉLITE';
    if (report.overallScore < 85) level = 'ZONE DE PERFORMANCE PRO';
    if (report.overallScore < 70) level = 'ZONE DE PERFORMANCE STANDARD';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: SPColors.primaryBlue.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: SPColors.primaryBlue.withOpacity(0.3)),
      ),
      child: Text(
        level,
        style: SPTypography.overline.copyWith(
          color: SPColors.primaryBlueLight,
          fontWeight: FontWeight.bold,
          fontSize: 9,
        ),
      ),
    );
  }

  Widget _buildRadarChartSection(PlayerReport report) {
    // Standard categories for the radar chart
    final List<String> standardCategories = [
      'PHYSICAL',
      'TECHNICAL',
      'TACTICAL',
      'MENTAL',
      'MEDICAL',
    ];

    final Map<String, double> categoryScores = {
      for (var cat in standardCategories) cat: 0.0,
    };

    final Map<String, int> counts = {
      for (var cat in standardCategories) cat: 0,
    };

    // Calculate real averages from test scores
    for (var ts in report.testScores) {
      final cat = ts.category.toUpperCase();
      // If it's a standard category, track it. If it's a new one (like STAMINA), 
      // we can either add it dynamically or map it if it makes sense.
      // For now, let's allow dynamic categories but prioritize the main 5.
      if (!categoryScores.containsKey(cat)) {
        categoryScores[cat] = 0.0;
        counts[cat] = 0;
      }
      
      categoryScores[cat] = categoryScores[cat]! + ts.score;
      counts[cat] = (counts[cat] ?? 0) + 1;
    }

    // Sort categories alphabetically for consistent chart layout
    final sortedCategories = categoryScores.keys.toList()..sort();
    final Map<String, double> finalScores = {};

    for (var cat in sortedCategories) {
      if ((counts[cat] ?? 0) > 0) {
        finalScores[cat] = categoryScores[cat]! / counts[cat]!;
      } else {
        finalScores[cat] = 0.0; // No data = 0, no more fake data!
      }
    }

    final List<RadarEntry> entries = finalScores.values.map((v) => RadarEntry(value: v)).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: SPColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: SPColors.borderPrimary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.hub_outlined, color: SPColors.primaryBlue, size: 18),
              const SizedBox(width: 8),
              Text(
                'Répartition de la Performance',
                style: SPTypography.bodyLarge.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 250,
            child: RadarChart(
              RadarChartData(
                dataSets: [
                  RadarDataSet(
                    fillColor: SPColors.primaryBlue.withOpacity(0.2),
                    borderColor: SPColors.primaryBlue,
                    entryRadius: 3,
                    dataEntries: entries,
                    borderWidth: 2,
                  ),
                ],
                radarBackgroundColor: Colors.transparent,
                borderData: FlBorderData(show: false),
                radarBorderData: const BorderSide(color: SPColors.borderPrimary, width: 1),
                radarShape: RadarShape.polygon,
                getTitle: (index, angle) {
                  return RadarChartTitle(
                    text: sortedCategories[index],
                    angle: angle,
                  );
                },
                titleTextStyle: SPTypography.overline.copyWith(color: SPColors.textTertiary, fontSize: 8),
                tickCount: 4,
                ticksTextStyle: const TextStyle(color: Colors.transparent, fontSize: 0),
                gridBorderData: const BorderSide(color: SPColors.borderPrimary, width: 1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAISynthesis(BuildContext context, PlayerReport report) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: SPColors.primaryBlue.withOpacity(0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: SPColors.primaryBlue.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.bolt, color: SPColors.primaryBlue, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'SYNTHÈSE DE PERFORMANCE IA',
                    style: SPTypography.overline.copyWith(
                      color: SPColors.primaryBlue,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.auto_awesome, color: SPColors.primaryBlue, size: 16),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                report.recommendation.isNotEmpty 
                  ? report.recommendation 
                  : "Aucune recommandation disponible pour le moment.",
                style: SPTypography.bodyMedium.copyWith(
                  color: SPColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildProfessionalPrescription(context, report),
      ],
    );
  }

  Widget _buildProfessionalPrescription(BuildContext context, PlayerReport report) {
    // Identifier les lacunes (scores < 70 dans les métriques détaillées)
    final weaknesses = report.testScores.where((s) => s.score < 70).toList();
    
    if (weaknesses.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.medical_services_outlined, color: SPColors.warning, size: 18),
            const SizedBox(width: 8),
            Text(
              'PRESCRIPTIONS D\'ENTRAÎNEMENT',
              style: SPTypography.overline.copyWith(
                color: SPColors.warning,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...weaknesses.map((w) => _buildPrescriptionCard(context, w, report)),
      ],
    );
  }

  Widget _buildPrescriptionCard(BuildContext context, TestScore weakness, PlayerReport report) {
    final player = report.eventPlayer is EventPlayer ? (report.eventPlayer as EventPlayer).player : null;
    final playerId = player?.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SPColors.warning.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SPColors.warning.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LACUNE DÉTECTÉE : ${weakness.testName.toUpperCase()}',
                  style: SPTypography.caption.copyWith(
                    color: SPColors.warning,
                    fontWeight: FontWeight.bold,
                    fontSize: 9,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'L\'IA recommande un travail de ${weakness.category.toLowerCase()} ciblé.',
                  style: SPTypography.bodySmall.copyWith(color: SPColors.textSecondary),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              _navigateToGenerator(context, report, weakness.testName);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: SPColors.warning,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('RÉSOUDRE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  void _navigateToGenerator(BuildContext context, PlayerReport report, String objective) {
    final player = report.eventPlayer is EventPlayer 
        ? (report.eventPlayer as EventPlayer).player 
        : null;
    
    if (player == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GeneratorForm(
          initialPlayerId: player.id,
          initialObjective: objective,
        ),
      ),
    );
  }

  Widget _buildDetailedMetrics(PlayerReport report) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'MÉTRIQUES DÉTAILLÉES',
          style: SPTypography.overline.copyWith(color: SPColors.textTertiary, letterSpacing: 1.1),
        ),
        const SizedBox(height: 16),
        ...report.testScores.map((score) => _buildMetricItem(score, report)),
      ],
    );
  }

  Widget _buildMetricItem(TestScore test, PlayerReport report) {
    IconData icon = Icons.speed;
    if (test.category.toLowerCase().contains('phys')) icon = Icons.fitness_center;
    if (test.category.toLowerCase().contains('tech')) icon = Icons.sports_soccer;
    if (test.category.toLowerCase().contains('tact')) icon = Icons.grid_view;

    String level = 'STANDARD';
    Color levelColor = SPColors.textSecondary;
    if (test.score > 85) {
      level = 'CLASSE ÉLITE';
      levelColor = SPColors.primaryBlueLight;
    } else if (test.score > 70) {
      level = 'STANDARD PRO';
      levelColor = SPColors.success;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SPColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SPColors.borderPrimary),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: SPColors.backgroundTertiary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: SPColors.primaryBlue, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  test.testName,
                  style: SPTypography.bodyLarge.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                Text(
                  level,
                  style: SPTypography.overline.copyWith(color: levelColor, fontSize: 8),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${test.score.toInt()}%', 
                style: SPTypography.h4.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.trending_up, color: SPColors.success, size: 12),
                  const SizedBox(width: 4),
                  Text(
                    report.scoreTrend.abs().toStringAsFixed(3),
                    style: SPTypography.caption.copyWith(
                      color: report.scoreTrend >= 0 ? SPColors.success : SPColors.error,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSendToAiButton(BuildContext context, PlayerReport report) {
    final player = report.eventPlayer is EventPlayer
        ? (report.eventPlayer as EventPlayer).player
        : null;

    if (player == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF2B3BEE).withOpacity(0.08),
            const Color(0xFF2B3BEE).withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF2B3BEE).withOpacity(0.25)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF2B3BEE).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.psychology, color: Color(0xFF2B3BEE), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI SCOUTING',
                      style: SPTypography.overline.copyWith(
                        color: const Color(0xFF2B3BEE),
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Envoyer ce joueur à l\'IA pour évaluation de recrutement',
                      style: SPTypography.caption.copyWith(
                        color: SPColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _handleSendToAi(context, player, report),
              icon: const Icon(Icons.send, size: 18),
              label: const Text('ENVOYER VERS AI SCOUTING'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2B3BEE),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSendToAi(
    BuildContext context,
    dynamic player, // SP Player
    PlayerReport report,
  ) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: Card(
          color: Color(0xFF1A1A2E),
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Color(0xFF2B3BEE)),
                SizedBox(height: 16),
                Text(
                  'Envoi vers AI Scouting...',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Mapping des stats et analyse IA en cours',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      await AiScoutingBridge.sendToAiScouting(
        player: player,
        report: report,
      );

      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog

        // Show success dialog with option to go to AI Scouting
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF1A1A2E),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Color(0xFF00C853), size: 24),
                SizedBox(width: 10),
                Text('Envoyé !', style: TextStyle(color: Colors.white)),
              ],
            ),
            content: Text(
              '${player.firstName} ${player.lastName} a été envoyé au module AI Scouting.\n\nL\'IA va analyser ses performances et fournir une recommandation de recrutement.',
              style: const TextStyle(color: Colors.white70, height: 1.5),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK', style: TextStyle(color: Colors.white54)),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  // Navigate to AI Campaign Screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => prov.ChangeNotifierProvider.value(
                        value: prov.Provider.of<CampaignProvider>(context, listen: false),
                        child: const AiCampaignScreen(),
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.psychology, size: 18),
                label: const Text('VOIR AI SCOUTING'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2B3BEE),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: SPColors.error,
          ),
        );
      }
    }
  }
}
