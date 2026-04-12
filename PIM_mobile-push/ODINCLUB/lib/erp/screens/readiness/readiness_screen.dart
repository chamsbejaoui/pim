import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../models/player.dart';
import '../../models/player_metrics.dart';
import '../../models/readiness_result.dart';
import '../../providers/players_provider.dart';
import '../../providers/readiness_provider.dart';

class ReadinessScreen extends StatefulWidget {
  const ReadinessScreen({super.key});

  @override
  State<ReadinessScreen> createState() => _ReadinessScreenState();
}

class _ReadinessScreenState extends State<ReadinessScreen> {
  String _matchDate = DateTime.now().toIso8601String().split('T').first;
  String _sortBy = 'score'; // score | name | position
  bool _filterRisk = false;
  String? _expandedPlayerId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReadinessProvider>().loadCached(_matchDate);
    });
  }

  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  // Build metrics from Player stats (no random demo data)
  List<PlayerMetrics> _buildMetrics(List<Player> players) {
    return players.map((p) {
      final stats = p.stats ?? {};
      return PlayerMetrics(
        playerId: p.id,
        playerName: p.fullName,
        position: p.position,
        acwr: _toDouble(stats['acwr']),
        trainingLoadKm: _toDouble(stats['trainingLoadKm'] ?? stats['training_load_km']),
        hrvScore: _toInt(stats['hrvScore'] ?? stats['hrv']),
        sleepHours: _toDouble(stats['sleepHours'] ?? stats['sleep_hours']),
        sleepQuality: _toInt(stats['sleepQuality'] ?? stats['sleep_quality']),
        muscularPainLevel: _toInt(stats['muscularPainLevel'] ?? stats['muscular_pain_level']),
        fatigueLevel: _toInt(stats['fatigueLevel'] ?? stats['fatigue_level']),
        injuryHistory: p.status == 'injured'
            ? (p.medicalNotes ?? 'Blessure musculaire')
            : 'Aucune blessure connue',
        daysSinceLastInjury: _toInt(stats['daysSinceLastInjury'] ?? stats['days_since_last_injury']),
        activeInjuryZones: stats['activeInjuryZones']?.toString(),
        lastMatchRating: _toDouble(stats['lastMatchRating'] ?? stats['last_match_rating']),
        goalsLast5: _toInt(stats['goalsLast5'] ?? stats['goals_last_5']),
        minutesLast5: _toInt(stats['minutesLast5'] ?? stats['minutes_last_5']),
        daysToMatch: _toInt(stats['daysToMatch'] ?? stats['days_to_match']) ?? 3,
        matchDate: _matchDate,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReadinessProvider>();
    final players = context.watch<PlayersProvider>().players;

    List<ReadinessResult> displayResults = List.from(provider.results);

    if (_filterRisk) {
      displayResults = displayResults.where((r) => r.score < 70).toList();
    }

    if (_sortBy == 'name') {
      displayResults.sort((a, b) => a.playerName.compareTo(b.playerName));
    } else if (_sortBy == 'position') {
      displayResults.sort((a, b) => a.playerName.compareTo(b.playerName));
    }
    // score sort is default (already sorted in provider)

    return Scaffold(
      backgroundColor: OdinTheme.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF020617),
                    OdinTheme.primaryBlue.withValues(alpha: 0.4),
                  ],
                ),
              ),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: OdinTheme.primaryBlue.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: OdinTheme.primaryBlue.withValues(alpha: 0.5)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.psychology_rounded, color: OdinTheme.primaryBlue, size: 14),
                            SizedBox(width: 6),
                            Text(
                              'AI MATCH READINESS',
                              style: TextStyle(color: OdinTheme.primaryBlue, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Google Gemini AI',
                          style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Match Readiness Score',
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ),
          ),

          // ─── Analyze button / progress ───────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: provider.isAnalyzing
                  ? _buildAnalyzingBanner(provider)
                  : _buildAnalyzeButton(players, provider),
            ),
          ),

          // ─── Team Availability Gauge ───────────────────────────────
          if (displayResults.isNotEmpty)
            SliverToBoxAdapter(
              child: _buildTeamAvailabilitySection(provider),
            )
          else
            SliverToBoxAdapter(
              child: _buildKpiRow(provider),
            ),

          // ─── Sort & Filter ───────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '● EFFECTIF (${displayResults.isEmpty ? players.length : displayResults.length} JOUEURS)',
                    style: const TextStyle(color: Color(0xFF6B7280), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _sortBtn('Score ↓', 'score'),
                      const SizedBox(width: 8),
                      _sortBtn('Nom A–Z', 'name'),
                      const SizedBox(width: 8),
                      _sortBtn('Poste', 'position'),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => setState(() => _filterRisk = !_filterRisk),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: _filterRisk
                                ? const Color(0xFFEF4444).withValues(alpha: 0.15)
                                : OdinTheme.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _filterRisk ? const Color(0xFFEF4444) : OdinTheme.cardBorder,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.warning_amber_rounded,
                                  color: Color(0xFFEF4444), size: 13),
                              const SizedBox(width: 4),
                              Text(
                                'À risque',
                                style: TextStyle(
                                  color: _filterRisk ? const Color(0xFFEF4444) : OdinTheme.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ─── Player cards ────────────────────────────────────────
          if (provider.results.isEmpty && !provider.isAnalyzing)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.psychology_outlined,
                        color: OdinTheme.textTertiary, size: 64),
                    const SizedBox(height: 16),
                    const Text(
                      'Aucune analyse disponible',
                      style: TextStyle(color: OdinTheme.textSecondary, fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Cliquez sur "Analyser l\'effectif" pour démarrer',
                      style: TextStyle(color: OdinTheme.textTertiary, fontSize: 13),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) {
                    // Show unanalyzed players as skeletons
                    if (i >= displayResults.length) {
                      final unanalyzedIdx = i - displayResults.length;
                      final unanalyzed = players
                          .where((p) => !displayResults.any((r) => r.playerId == p.id))
                          .toList();
                      if (unanalyzedIdx < unanalyzed.length) {
                        return _buildSkeletonCard(unanalyzed[unanalyzedIdx]);
                      }
                      return null;
                    }
                    return _buildPlayerCard(displayResults[i]);
                  },
                  childCount: displayResults.length +
                      (provider.isAnalyzing
                          ? players
                              .where((p) => !displayResults.any((r) => r.playerId == p.id))
                              .length
                          : 0),
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  // ─── Analyze button ──────────────────────────────────────────────────
  Widget _buildAnalyzeButton(List<Player> players, ReadinessProvider provider) {
    return GestureDetector(
      onTap: () {
        final metrics = _buildMetrics(players);
        provider.analyzeSquad(metrics, _matchDate);
      },
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4F46E5).withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.psychology_rounded, color: Colors.white, size: 22),
            const SizedBox(width: 10),
            Text(
              provider.results.isEmpty
                  ? '🤖  Analyser l\'effectif (${players.length} joueurs)'
                  : '🔄  Re-analyser l\'effectif',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Progress banner ─────────────────────────────────────────────────
  Widget _buildAnalyzingBanner(ReadinessProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF4F46E5).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF4F46E5).withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(Color(0xFF4F46E5)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Analyse ${provider.currentPlayerName ?? '...'}  (${provider.analyzedCount}/${provider.totalToAnalyze})',
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: provider.progress,
                  backgroundColor: Colors.white12,
                  valueColor: const AlwaysStoppedAnimation(Color(0xFF4F46E5)),
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── KPI Row ─────────────────────────────────────────────────────────
  Widget _buildKpiRow(ReadinessProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          _kpiCard('SCORE ÉQUIPE', '${provider.teamScore}%',
              const Color(0xFF10B981), true),
          const SizedBox(width: 8),
          _kpiCard('OPTIMAL (≥85)', '${provider.optimalCount}',
              const Color(0xFF10B981), false),
          const SizedBox(width: 8),
          _kpiCard('ATTENTION (60–84)', '${provider.attentionCount}',
              const Color(0xFFF59E0B), false),
          const SizedBox(width: 8),
          _kpiCard('RISQUE (<60)', '${provider.riskCount}',
              const Color(0xFFEF4444), false),
        ],
      ),
    );
  }

  // ─── Team Availability Gauge Section ──────────────────────────────────
  Widget _buildTeamAvailabilitySection(ReadinessProvider provider) {
    if (provider.results.isEmpty) return const SizedBox();

    // Calculate averages for factors
    int avgAcwr = 0;
    int avgHrv = 0;
    int avgSleep = 0;
    int riskCount = 0;

    for (var r in provider.results) {
      if (r.score < 60) riskCount++;
      // We parse out the values from the factor labels (which is a bit hacky but works for UI)
      for (var f in r.factors) {
        if (f.label.contains('ACWR')) {
          final val = RegExp(r'([\d.]+)').firstMatch(f.label)?.group(1);
          if (val != null) {
            double d = double.tryParse(val) ?? 1.0;
            // map ACWR 0.8-1.2 to high %, >1.5 or <0.5 to low %
            int pct = 100;
            if (d > 1.2) pct = math.max(20, 100 - ((d - 1.2) * 100).round());
            if (d < 0.8) pct = math.max(20, 100 - ((0.8 - d) * 100).round());
            avgAcwr += pct;
          }
        }
        if (f.label.contains('Récupération')) {
          final val = RegExp(r'(\d+)').firstMatch(f.label)?.group(1);
          if (val != null) avgHrv += int.parse(val);
        }
        if (f.label.contains('Sommeil')) {
          final val = RegExp(r'\((\d+)%\)').firstMatch(f.label)?.group(1);
          if (val != null) avgSleep += int.parse(val);
        }
      }
    }

    final n = provider.results.length;
    avgAcwr = n > 0 ? (avgAcwr / n).round() : 0;
    avgHrv = n > 0 ? (avgHrv / n).round() : 0;
    avgSleep = n > 0 ? (avgSleep / n).round() : 0;
    final riskPct = n > 0 ? ((riskCount / n) * 100).round() : 0;
    final formPct = provider.teamScore; // close enough

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF111827),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '● DISPONIBILITÉ ÉQUIPE',
              style: TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 24),

            // Semi-circle gauge (using a simpler visual rep here)
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 160,
                    height: 100, // Reduced height to fit semi-circle
                    child: CustomPaint(
                      painter: _GaugePainter(progress: provider.teamScore / 100),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${provider.teamScore}%',
                          style: const TextStyle(
                            color: Color(0xFF38BDF8),
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1,
                          ),
                        ),
                        const Text(
                          'SCORE MOYEN',
                          style: TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 20,
                    child: Text('0', style: TextStyle(color: OdinTheme.accentRed, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 20,
                    child: Text('100', style: TextStyle(color: OdinTheme.accentGreen, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            const Text(
              '● FACTEURS ANALYSÉS',
              style: TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 16),

            _buildFactorBar('Charge GPS', avgAcwr, const Color(0xFF38BDF8)),
            _buildFactorBar('Récupération HRV', avgHrv, const Color(0xFF34D399)),
            _buildFactorBar('Qualité sommeil', avgSleep, const Color(0xFFFBBF24)),
            _buildFactorBar('Risque blessure', riskPct, const Color(0xFFFB7185)),
            _buildFactorBar('Forme récente', formPct, const Color(0xFF818CF8)),
          ],
        ),
      ),
    );
  }

  Widget _buildFactorBar(String label, int value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF9CA3AF),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: value / 100,
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 35,
            child: Text(
              label.contains('Score') || label == 'Récupération HRV' 
                  ? '$value' 
                  : '$value%',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _kpiCard(String label, String value, Color color, bool big) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: OdinTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: Color(0xFF6B7280), fontSize: 8, fontWeight: FontWeight.w700, letterSpacing: 0.5),
              maxLines: 2,
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: big ? 26 : 22,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Animated player card ───────────────────────────────────────────
  Widget _buildPlayerCard(ReadinessResult result) {
    final isExpanded = _expandedPlayerId == result.playerId;

    return GestureDetector(
      onTap: () => setState(() =>
          _expandedPlayerId = isExpanded ? null : result.playerId),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF111827),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isExpanded
                ? result.statusColor.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.05),
            width: isExpanded ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            // ── Top row ──────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Animated score ring
                  _ScoreRing(score: result.score, color: result.statusColor),
                  const SizedBox(width: 16),
                  // Player info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                result.playerName,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: result.statusColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '● ${result.statusLabel}',
                                style: TextStyle(
                                    color: result.statusColor, fontSize: 10, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: result.factors.take(3).map((f) {
                            return Text(
                              '${f.icon} ${f.label}',
                              style: TextStyle(
                                color: f.type == 'ok'
                                    ? const Color(0xFF10B981)
                                    : f.type == 'warn'
                                        ? const Color(0xFFF59E0B)
                                        : const Color(0xFFEF4444),
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                    color: OdinTheme.textTertiary,
                    size: 20,
                  ),
                ],
              ),
            ),

            // ── Expanded details ──────────────────────────
            if (isExpanded) ...[
              const Divider(color: Colors.white12, height: 1),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // All factors
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: result.factors.map((f) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: (f.type == 'ok'
                              ? const Color(0xFF10B981)
                              : f.type == 'warn'
                                  ? const Color(0xFFF59E0B)
                                  : const Color(0xFFEF4444))
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: (f.type == 'ok'
                                    ? const Color(0xFF10B981)
                                    : f.type == 'warn'
                                        ? const Color(0xFFF59E0B)
                                        : const Color(0xFFEF4444))
                                .withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text('${f.icon} ${f.label}',
                            style: const TextStyle(color: Colors.white70, fontSize: 11)),
                      )).toList(),
                    ),
                    if (result.analysis != null && result.analysis!.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      const Text(
                        '🤖 Analyse IA',
                        style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        result.analysis!,
                        style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.5),
                      ),
                    ],
                    if (result.recommendation != null && result.recommendation!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: result.statusColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: result.statusColor.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.tips_and_updates_rounded,
                                color: result.statusColor, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                result.recommendation!,
                                style: TextStyle(
                                    color: result.statusColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        result.usedAi ? '✨ Gemini AI' : '📊 Formule mathématique',
                        style: const TextStyle(color: Color(0xFF6B7280), fontSize: 10),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─── Skeleton card (not yet analyzed) ───────────────────────────────
  Widget _buildSkeletonCard(Player player) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.hourglass_top_rounded,
                color: Color(0xFF374151), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(player.fullName,
                    style: const TextStyle(color: Colors.white60, fontSize: 15)),
                const SizedBox(height: 4),
                const Text('En attente d\'analyse...',
                    style: TextStyle(color: Color(0xFF374151), fontSize: 12)),
              ],
            ),
          ),
          const Text('—', style: TextStyle(color: Color(0xFF374151), fontSize: 16)),
        ],
      ),
    );
  }

  // ─── Sort button ─────────────────────────────────────────────────────
  Widget _sortBtn(String label, String key) {
    final active = _sortBy == key;
    return GestureDetector(
      onTap: () => setState(() => _sortBy = key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: active ? OdinTheme.primaryBlue : OdinTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? OdinTheme.primaryBlue : OdinTheme.cardBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : OdinTheme.textSecondary,
            fontSize: 12,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// ─── Animated SVG-like Score Ring ───────────────────────────────────────
class _ScoreRing extends StatefulWidget {
  final int score;
  final Color color;

  const _ScoreRing({required this.score, required this.color});

  @override
  State<_ScoreRing> createState() => _ScoreRingState();
}

class _ScoreRingState extends State<_ScoreRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _anim = Tween<double>(begin: 0, end: widget.score / 100).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => SizedBox(
        width: 56,
        height: 56,
        child: CustomPaint(
          painter: _RingPainter(progress: _anim.value, color: widget.color),
          child: Center(
            child: Text(
              '${widget.score}',
              style: TextStyle(
                color: widget.color,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;

  const _RingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 6) / 2;

    // Background ring
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = color.withValues(alpha: 0.1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );

    // Progress arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}

// ─── Team Availability Gauge Painter ────────────────────────────────────
class _GaugePainter extends CustomPainter {
  final double progress;

  const _GaugePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2 - 10;

    // Background track
    final bgPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCircle(center: center, radius: radius);

    canvas.drawArc(rect, math.pi, math.pi, false, bgPaint);

    // Dynamic gradient progress
    final double sweepAngle = math.pi * progress;

    const startColor = Color(0xFFEF4444); // Red
    const midColor = Color(0xFFFACC15); // Yellow
    const endColor = Color(0xFF10B981); // Green

    final gradient = SweepGradient(
      startAngle: math.pi,
      endAngle: 2 * math.pi,
      colors: const [startColor, midColor, endColor],
      stops: const [0.0, 0.5, 1.0],
    );

    final progressPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, math.pi, sweepAngle, false, progressPaint);
  }

  @override
  bool shouldRepaint(_GaugePainter old) => old.progress != progress;
}
