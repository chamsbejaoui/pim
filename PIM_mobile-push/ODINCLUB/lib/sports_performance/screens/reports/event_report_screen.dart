import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/event.dart';
import '../../models/event_report.dart';
import '../../providers/events_provider.dart';
import '../../providers/reports_provider.dart';
import '../../theme/sp_colors.dart';
import '../../theme/sp_typography.dart';
import '../reports/player_report_screen.dart';
import 'widgets/stat_card.dart';
import '../../../services/ai_scouting_bridge.dart';
import '../../services/reports_service.dart';
import '../../../screens/ai/ai_campaign_screen.dart';
import 'package:provider/provider.dart' as prov;
import '../../../providers/campaign_provider.dart';

class EventReportScreen extends ConsumerStatefulWidget {
  final String eventId;

  const EventReportScreen({
    super.key,
    required this.eventId,
  });

  @override
  ConsumerState<EventReportScreen> createState() => _EventReportScreenState();
}

class _EventReportScreenState extends ConsumerState<EventReportScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final reportAsyncValue = ref.watch(eventReportProvider(widget.eventId));
    final generationAsyncValue = ref.watch(reportGenerationProvider);

    final eventAsyncValue = ref.watch(eventProvider(widget.eventId));
    
    return Scaffold(
      backgroundColor: SPColors.backgroundPrimary,
      appBar: AppBar(
        title: Text(
          'RÉSULTATS DU SUIVI',
          style: SPTypography.h4.copyWith(color: SPColors.textPrimary),
        ),
        backgroundColor: SPColors.backgroundPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.psychology, color: Color(0xFF2B3BEE)),
            tooltip: 'Envoyer tous vers AI Scouting',
            onPressed: () {
              final reportAsync = ref.read(eventReportProvider(widget.eventId));
              reportAsync.whenData((report) {
                if (report.ranking.isNotEmpty) {
                  _handleSendAllToAi(context, ref, report);
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined, color: SPColors.primaryBlue),
            onPressed: () {
              // TODO: Share report
            },
          ),
        ],
      ),
      body: reportAsyncValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildEmptyReportState(generationAsyncValue, eventAsyncValue),
        data: (report) {
          if (report.ranking.isEmpty) {
            return _buildEmptyReportState(generationAsyncValue, eventAsyncValue);
          }

          final filteredRanking = report.ranking.where((r) {
            return r.player.fullName.toLowerCase().contains(_searchQuery.toLowerCase());
          }).toList();

          final topPlayer = filteredRanking.isNotEmpty ? filteredRanking.first : null;
          final otherPlayers = filteredRanking.length > 1 ? filteredRanking.sublist(1) : <RankedPlayer>[];

          return Column(
            children: [
              if (topPlayer != null && _searchQuery.isEmpty) _buildTopPerformerHero(topPlayer, report),
              _buildSearchBar(),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: _searchQuery.isEmpty ? otherPlayers.length : filteredRanking.length,
                  itemBuilder: (context, index) {
                    final player = _searchQuery.isEmpty ? otherPlayers[index] : filteredRanking[index];
                    return _buildRankingItem(player);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyReportState(
    AsyncValue<bool> generationAsyncValue, 
    AsyncValue<Event> eventAsyncValue
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.analytics_outlined, size: 64, color: SPColors.textTertiary),
            const SizedBox(height: 24),
            Text(
              'Aucun classement trouvé',
              style: SPTypography.h4.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 12),
            eventAsyncValue.when(
              loading: () => const CircularProgressIndicator(),
              error: (err, _) => Text('Error loading event status: $err', style: const TextStyle(color: SPColors.error)),
              data: (event) {
                if (!event.isCompleted) {
                  return Column(
                    children: [
                      Text(
                        'Ce suivi est actuellement actif. Vous devez terminer le suivi dans l\'écran de la fiche avant de générer les rapports.',
                        textAlign: TextAlign.center,
                        style: SPTypography.bodyMedium.copyWith(color: SPColors.warning),
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(backgroundColor: SPColors.backgroundSecondary),
                        child: const Text('RETOUR À LA FICHE'),
                      ),
                    ],
                  );
                }
                
                return Column(
                  children: [
                    Text(
                      'Générez les rapports pour calculer les scores et les classements pour ce suivi.\n\nAssurez-vous d\'avoir saisi et enregistré des résultats de test pour au moins un joueur.',
                      textAlign: TextAlign.center,
                      style: SPTypography.bodyMedium.copyWith(color: SPColors.textSecondary),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: generationAsyncValue.isLoading 
                            ? null 
                            : () => _handleGenerateReports(),
                        icon: generationAsyncValue.isLoading 
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.auto_awesome),
                        label: const Text('GÉNÉRER TOUS LES RAPPORTS'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: SPColors.primaryBlue,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            if (generationAsyncValue.hasError) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: SPColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: SPColors.error.withOpacity(0.3)),
                ),
                child: Text(
                  generationAsyncValue.error.toString().replaceAll('Exception: ', ''),
                  style: SPTypography.caption.copyWith(color: SPColors.error),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _handleGenerateReports() async {
    final success = await ref.read(reportGenerationProvider.notifier).generateAllReports(widget.eventId);
    if (!mounted) return;
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rapports générés avec succès !'),
          backgroundColor: SPColors.success,
        ),
      );
    } else {
      final error = ref.read(reportGenerationProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Generation failed: $error'),
          backgroundColor: SPColors.error,
        ),
      );
    }
  }

  Widget _buildTopPerformerHero(RankedPlayer player, EventReport report) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: SPColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: SPColors.primaryBlue.withOpacity(0.2)),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            SPColors.primaryBlue.withOpacity(0.1),
            SPColors.backgroundSecondary,
          ],
        ),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              // Outer Glow
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: SPColors.primaryBlue.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
              ),
              // Avatar Border
              Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [SPColors.primaryBlue, SPColors.primaryBlueLight],
                  ),
                ),
                child: CircleAvatar(
                  radius: 48,
                  backgroundColor: SPColors.backgroundPrimary,
                  backgroundImage: player.player.photo != null ? NetworkImage(player.player.photo!) : null,
                  child: player.player.photo == null 
                      ? Text(player.player.firstName[0], style: const TextStyle(fontSize: 32, color: Colors.white))
                      : null,
                ),
              ),
              // Rank Badge
              Positioned(
                bottom: 0,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: SPColors.primaryBlue,
                    shape: BoxShape.circle,
                    border: Border.all(color: SPColors.backgroundSecondary, width: 2),
                  ),
                  child: const Center(
                    child: Text('1', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ),
              ),
              // Top Performer Label
              Positioned(
                top: 0,
                right: -20,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: SPColors.primaryBlue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'TOP PERFORMER',
                    style: SPTypography.overline.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 8,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            player.player.fullName,
            style: SPTypography.h3.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            player.player.position.toUpperCase(),
            style: SPTypography.bodySmall.copyWith(
              color: SPColors.primaryBlueLight,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                player.score.toStringAsFixed(1),
                style: SPTypography.h1.copyWith(
                  color: SPColors.primaryBlue,
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'SCORE GLOBAL',
                style: SPTypography.overline.copyWith(
                  color: SPColors.textTertiary,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          // Stats Row
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: SPColors.borderPrimary.withOpacity(0.1)),
              ),
            ),
            child: _buildDynamicStatsRow(report),
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicStatsRow(EventReport report) {
    // Get categories with their average scores
    final categories = report.statistics.byCategory;
    
    if (categories.isEmpty) {
      return Center(
        child: Text(
          'NO CATEGORY DATA AVAILABLE',
          style: SPTypography.overline.copyWith(color: SPColors.textTertiary),
        ),
      );
    }

    // Sort categories (we could prioritize Physical, etc., or just take the first 3)
    final sortedKeys = categories.keys.toList()..sort();
    final topKeys = sortedKeys.take(3).toList();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        for (int i = 0; i < topKeys.length; i++) ...[
          _buildMiniStat(
            topKeys[i].toUpperCase(), 
            categories[topKeys[i]]!.avg.toStringAsFixed(0),
          ),
          if (i < topKeys.length - 1) _buildVerticalDivider(),
        ],
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 24,
      width: 1,
      color: SPColors.borderPrimary.withOpacity(0.2),
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: SPTypography.overline.copyWith(color: SPColors.textTertiary, fontSize: 8),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: SPTypography.h4.copyWith(color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search, color: SPColors.textTertiary),
                hintText: 'Chercher des athlètes...',
                hintStyle: TextStyle(color: SPColors.textTertiary.withOpacity(0.5)),
                fillColor: SPColors.backgroundSecondary,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: SPColors.backgroundSecondary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.filter_list, color: SPColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildRankingItem(RankedPlayer ranked) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: SPColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: SPColors.borderPrimary.withOpacity(0.5)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PlayerReportScreen(eventPlayerId: ranked.eventPlayerId),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Rank Number
              SizedBox(
                width: 32,
                child: Text(
                  '${ranked.rank}',
                  style: SPTypography.h4.copyWith(
                    color: SPColors.textTertiary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Player Avatar
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: SPColors.borderPrimary, width: 1),
                ),
                child: CircleAvatar(
                  radius: 22,
                  backgroundColor: SPColors.backgroundTertiary,
                  backgroundImage: ranked.player.photo != null ? NetworkImage(ranked.player.photo!) : null,
                  child: ranked.player.photo == null 
                      ? Text(ranked.player.firstName[0], style: const TextStyle(color: Colors.white, fontSize: 16))
                      : null,
                ),
              ),
              const SizedBox(width: 16),
              // Player Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ranked.player.fullName,
                      style: SPTypography.bodyLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      ranked.player.position.toUpperCase(),
                      style: SPTypography.overline.copyWith(
                        color: SPColors.textTertiary,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
              // Score & Delta
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    ranked.score.toStringAsFixed(1),
                    style: SPTypography.h4.copyWith(
                      color: SPColors.primaryBlue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  if (ranked.scoreTrend != 0)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          ranked.scoreTrend > 0
                              ? Icons.arrow_drop_up
                              : Icons.arrow_drop_down,
                          color: ranked.scoreTrend > 0
                              ? SPColors.success
                              : SPColors.error,
                          size: 16,
                        ),
                        Text(
                          ranked.scoreTrend.abs().toStringAsFixed(1),
                          style: SPTypography.caption.copyWith(
                            color: ranked.scoreTrend > 0
                                ? SPColors.success
                                : SPColors.error,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    )
                  else
                    Text(
                      '—',
                      style: SPTypography.caption.copyWith(
                        color: SPColors.textTertiary,
                        fontSize: 10,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleSendAllToAi(
    BuildContext context,
    WidgetRef ref,
    EventReport report,
  ) async {
    final ranking = report.ranking;
    if (ranking.isEmpty) return;

    // Confirm dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.psychology, color: Color(0xFF2B3BEE), size: 24),
            SizedBox(width: 10),
            Text('AI Scouting', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Text(
          'Envoyer les ${ranking.length} joueurs de cet événement vers le module AI Scouting pour évaluation ?\n\nL\'IA analysera leurs performances et fournira des recommandations de recrutement.',
          style: const TextStyle(color: Colors.white70, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.send, size: 16),
            label: const Text('ENVOYER TOUS'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2B3BEE),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    // Show progress dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: Card(
          color: const Color(0xFF1A1A2E),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: Color(0xFF2B3BEE)),
                const SizedBox(height: 16),
                Text(
                  'Envoi de ${ranking.length} joueurs...',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Récupération des rapports et mapping vers l\'IA',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final reportsService = ref.read(reportsServiceProvider);
      final playerReports = <({
        dynamic player,
        dynamic report,
      })>[];

      // Fetch individual player reports for each ranked player
      for (final ranked in ranking) {
        if (ranked.eventPlayerId.isEmpty) continue;
        try {
          final playerReport = await reportsService.getPlayerReport(ranked.eventPlayerId);
          playerReports.add((
            player: ranked.player,
            report: playerReport,
          ));
        } catch (_) {
          // Skip players without reports
        }
      }

      // Send all to AI
      int success = 0;
      int failed = 0;

      for (final entry in playerReports) {
        try {
          await AiScoutingBridge.sendToAiScouting(
            player: entry.player,
            report: entry.report,
          );
          success++;
        } catch (_) {
          failed++;
        }
      }

      if (mounted) {
        Navigator.pop(context); // Close progress dialog

        // Show result
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF1A1A2E),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Icon(
                  failed == 0 ? Icons.check_circle : Icons.warning_amber,
                  color: failed == 0 ? const Color(0xFF00C853) : Colors.orange,
                  size: 24,
                ),
                const SizedBox(width: 10),
                const Text('Résultat', style: TextStyle(color: Colors.white)),
              ],
            ),
            content: Text(
              '$success joueur(s) envoyé(s) avec succès vers AI Scouting.${failed > 0 ? '\n$failed joueur(s) échoué(s).' : ''}\n\nL\'IA va analyser les performances et fournir des recommandations.',
              style: const TextStyle(color: Colors.white70, height: 1.5),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK', style: TextStyle(color: Colors.white54)),
              ),
              if (success > 0)
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close progress dialog
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
