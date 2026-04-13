import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../../../user_management/models/user_management_models.dart';
import '../providers/cognitive_lab_provider.dart';
import '../models/cognitive_session.dart';
import 'cognitive_test_flow_screen.dart';
import 'tests/tactical_memory_screen.dart';
import 'player_medical_sheet_screen.dart';
import 'metabolic_scanner_screen.dart';

class CognitiveDashboardScreen extends StatefulWidget {
  final SessionModel session;
  final String? targetPlayerId;
  final String? targetPlayerName;
  final bool isReadOnly;

  const CognitiveDashboardScreen({
    super.key,
    required this.session,
    this.targetPlayerId,
    this.targetPlayerName,
    this.isReadOnly = false,
  });

  @override
  State<CognitiveDashboardScreen> createState() => _CognitiveDashboardScreenState();
}

class _CognitiveDashboardScreenState extends State<CognitiveDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final idToFetch = widget.targetPlayerId ?? widget.session.userId;
      context.read<CognitiveLabProvider>().fetchDashboard(idToFetch);
    });
  }

  Color _getStatusColor(String? status) {
    switch (status?.toUpperCase()) {
      case 'READY':
        return Colors.cyanAccent;
      case 'NORMAL':
        return Colors.greenAccent;
      case 'FATIGUED':
        return Colors.orangeAccent;
      case 'OVERLOADED':
        return Colors.redAccent;
      case 'CRITICAL':
      case 'RECOVERY REQUIRED':
        return Colors.red;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('COGNITIVE PERFORMANCE LAB', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 14)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<CognitiveLabProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator(color: Colors.cyanAccent));
          }

          final session = provider.latestSession;

          return Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.6),
                radius: 1.5,
                colors: [
                  const Color(0xFF1E293B).withOpacity(0.4),
                  const Color(0xFF0F172A),
                ],
              ),
            ),
            child: RefreshIndicator(
              onRefresh: () async {
                final idToFetch = widget.targetPlayerId ?? widget.session.userId;
                await context.read<CognitiveLabProvider>().fetchDashboard(idToFetch);
              },
              backgroundColor: const Color(0xFF1E293B),
              color: Colors.cyanAccent,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(left: 24, right: 24, top: 110, bottom: 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(session),
                    const SizedBox(height: 40),
                    if (session != null && session.scores != null) ...[
                      _buildMainScore(session),
                      const SizedBox(height: 48),
                      _buildGlassCard(
                        title: "COGNITIVE PROFILE",
                        subtitle: "Multi-dimensional performance overview",
                        child: _buildRadarChart(session),
                      ),
                      const SizedBox(height: 24),
                      if (session.scores?.trainingReadiness != null)
                        _buildTrainingReadinessBadge(session.scores!.trainingReadiness!),
                      const SizedBox(height: 24),
                      _buildAiRecommendationCard(session.aiRecommendationText),
                      const SizedBox(height: 16),
                      _buildTrainingSuggestionCard(session.trainingSuggestion),
                    ] else ...[
                      _buildEmptyState(),
                    ],
                    const SizedBox(height: 48),
                    if (!widget.isReadOnly) ...[
                      _buildEliteStartButton(),
                      const SizedBox(height: 16),
                      _buildStandaloneTacticalButton(),
                      const SizedBox(height: 16),
                      _buildNutritionLabButtons(),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGlassCard({required String title, required String subtitle, required Widget child, Color? accentColor}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 2)),
              Text(subtitle, style: const TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.w500)),
              const SizedBox(height: 24),
              child,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(CognitiveSession? session) {
    final statusColor = _getStatusColor(session?.aiStatus);
    final playerName = session?.playerName ?? widget.targetPlayerName ?? 'Utilisateur';
    final playerPosition = session?.playerPosition ?? 'Joueur';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Center(
                child: Text(
                  playerName.isNotEmpty ? playerName[0].toUpperCase() : 'P',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    playerName.toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1),
                  ),
                  Text(
                    playerPosition.toUpperCase(),
                    style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "READINESS STATUS",
                  style: TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                    boxShadow: [BoxShadow(color: statusColor.withOpacity(0.1), blurRadius: 10, spreadRadius: 1)],
                  ),
                  child: Text(
                    session?.aiStatus?.toUpperCase() ?? 'PENDING',
                    style: TextStyle(color: statusColor, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1),
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.local_fire_department_rounded, color: Colors.orangeAccent, size: 20),
                  SizedBox(width: 8),
                  Text("STREAK: 1", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMainScore(dynamic session) {
    final statusColor = _getStatusColor(session.aiStatus);
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background Glow
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: statusColor.withOpacity(0.2), blurRadius: 60, spreadRadius: 10)],
            ),
          ),
          // Ring
          SizedBox(
            width: 200,
            height: 200,
            child: CircularProgressIndicator(
              value: (session.scores?.mentalScore ?? 0) / 100,
              strokeWidth: 10,
              backgroundColor: Colors.white.withOpacity(0.03),
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              strokeCap: StrokeCap.round,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "${session.scores?.mentalScore ?? '--'}",
                style: const TextStyle(color: Colors.white, fontSize: 64, fontWeight: FontWeight.w900),
              ),
              const Text(
                "READINESS SCORE",
                style: TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2),
              ),
            ],
          ),
          if (session.scores?.decisionScore != null || session.scores?.wellnessScore != null)
            Positioned(
              bottom: -15,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (session.scores?.decisionScore != null)
                    _buildSubScoreChip("DEC", session.scores!.decisionScore!, Colors.cyanAccent),
                  if (session.scores?.decisionScore != null && session.scores?.wellnessScore != null)
                    const SizedBox(width: 8),
                  if (session.scores?.wellnessScore != null)
                    _buildSubScoreChip("WEL", session.scores!.wellnessScore!, Colors.purpleAccent),
                  if (session.scores?.tacticalIqScore != null) ...[
                    const SizedBox(width: 8),
                    _buildSubScoreChip("TAC", session.scores!.tacticalIqScore!, Colors.orangeAccent),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSubScoreChip(String label, int score, Color color) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "$label ",
                style: const TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.w900),
              ),
              Text(
                "$score",
                style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRadarChart(dynamic session) {
    final reactionScore = (session.scores?.reactionScore ?? 0).toDouble();
    final focusScore = (session.scores?.focusScore ?? 0).toDouble();
    final memoryScore = (session.scores?.memoryScore ?? 0).toDouble();
    final tacticalScore = (session.scores?.tacticalIqScore ?? 0).toDouble();

    return Column(
      children: [
        SizedBox(
          height: 220,
          child: RadarChart(
            RadarChartData(
              radarShape: RadarShape.polygon,
              tickCount: 4,
              ticksTextStyle: const TextStyle(color: Colors.transparent, fontSize: 10),
              radarBorderData: const BorderSide(color: Colors.white12),
              gridBorderData: const BorderSide(color: Colors.white10, width: 1),
              titleTextStyle: const TextStyle(color: Colors.white30, fontSize: 9, fontWeight: FontWeight.bold),
              titlePositionPercentageOffset: 0.15,
              dataSets: [
                RadarDataSet(
                  fillColor: Colors.cyanAccent.withOpacity(0.15),
                  borderColor: Colors.cyanAccent,
                  borderWidth: 2,
                  entryRadius: 3,
                  dataEntries: [
                    RadarEntry(value: reactionScore),
                    RadarEntry(value: focusScore),
                    RadarEntry(value: memoryScore),
                    if (session.scores?.tacticalIqScore != null) RadarEntry(value: tacticalScore),
                  ],
                ),
              ],
              getTitle: (index, angle) {
                final titles = ['REACTION', 'FOCUS', 'MEMORY'];
                if (session.scores?.tacticalIqScore != null) titles.add('VISION');
                return RadarChartTitle(text: titles[index], angle: angle);
              },
            ),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _radarLegend('REACTION', reactionScore, Colors.cyanAccent),
            _radarLegend('FOCUS', focusScore, Colors.cyanAccent),
            _radarLegend('MEMORY', memoryScore, Colors.cyanAccent),
            if (session.scores?.tacticalIqScore != null)
              _radarLegend('VISION', tacticalScore, Colors.orangeAccent),
          ],
        ),
        if (session.scores?.tacticalProfile != null) ...[
          const SizedBox(height: 16),
          _buildTacticalProfileBadge(session.scores!.tacticalProfile!),
        ],
      ],
    );
  }

  Widget _buildTacticalProfileBadge(String profile) {
    Color badgeColor;
    if (profile == 'Scanner') badgeColor = Colors.cyanAccent;
    else if (profile == 'Standard') badgeColor = Colors.amber;
    else badgeColor = Colors.redAccent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: badgeColor.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.remove_red_eye, color: badgeColor, size: 16),
          const SizedBox(width: 8),
          Text(
            "VIZ PROFILE: ${profile.toUpperCase()}",
            style: TextStyle(color: badgeColor, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
          ),
        ],
      ),
    );
  }

  Widget _radarLegend(String label, double value, Color color) {
    return Column(
      children: [
        Text(value.toStringAsFixed(0), style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white24, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
      ],
    );
  }

  Widget _buildAiRecommendationCard(String? recommendedText) {
    return _buildGlassCard(
      title: "AI PERFORMANCE ANALYSIS",
      subtitle: "Detailed cognitive interpretation",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bolt_rounded, color: Colors.cyanAccent, size: 20),
              const SizedBox(width: 8),
              const Text("NEURAL FEEDBACK", style: TextStyle(color: Colors.cyanAccent, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            recommendedText ?? 'Analyzing performance data...',
            style: const TextStyle(color: Colors.white, height: 1.6, fontSize: 14, fontWeight: FontWeight.w400),
          ),
        ],
      ),
    );
  }

  Widget _buildTrainingReadinessBadge(String readiness) {
    Color color;
    IconData icon;

    switch (readiness.toUpperCase()) {
      case 'FULL TRAINING':
        color = Colors.cyanAccent;
        icon = Icons.bolt_rounded;
        break;
      case 'NORMAL TRAINING':
        color = Colors.greenAccent;
        icon = Icons.check_circle_outline_rounded;
        break;
      case 'LIGHT TRAINING':
        color = Colors.orangeAccent;
        icon = Icons.warning_amber_rounded;
        break;
      case 'RECOVERY DAY':
        color = Colors.redAccent;
        icon = Icons.bed_rounded;
        break;
      default:
        color = Colors.blueGrey;
        icon = Icons.help_outline_rounded;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
          decoration: BoxDecoration(
            color: color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: color.withOpacity(0.2), width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "TRAINING ADAPTATION",
                      style: TextStyle(color: Colors.white24, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      readiness.toUpperCase(),
                      style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrainingSuggestionCard(String? suggestion) {
    return _buildGlassCard(
      title: "LOAD OPTIMIZATION",
      subtitle: "Specific training adjustments",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.fitness_center_rounded, color: Colors.purpleAccent, size: 20),
              const SizedBox(width: 8),
              const Text("SUGGESTED INTENSITY", style: TextStyle(color: Colors.purpleAccent, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            suggestion ?? 'Calculating optimal load...',
            style: const TextStyle(color: Colors.white, height: 1.6, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 80),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          const Icon(Icons.psychology_outlined, color: Colors.white10, size: 80),
          const SizedBox(height: 24),
          const Text(
            "NO DATA FOR TODAY",
            style: TextStyle(color: Colors.white24, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 2),
          ),
          const SizedBox(height: 8),
          const Text(
            "Complete your daily assessment to unlock scores.",
            style: TextStyle(color: Colors.white10, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildEliteStartButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.cyanAccent.withOpacity(0.2), blurRadius: 20, spreadRadius: -5),
        ],
      ),
      child: ElevatedButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CognitiveTestFlowScreen(
                session: widget.session,
                targetPlayerId: widget.targetPlayerId,
              ),
            ),
          );

          if (result == true) {
            final idToFetch = widget.targetPlayerId ?? widget.session.userId;
            context.read<CognitiveLabProvider>().fetchDashboard(idToFetch);
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.cyanAccent,
          foregroundColor: const Color(0xFF0F172A),
          padding: const EdgeInsets.symmetric(vertical: 22),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 0,
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.play_arrow_rounded, size: 28),
            SizedBox(width: 12),
            Text(
              "START COGNITIVE ASSESSMENT",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStandaloneTacticalButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orangeAccent.withOpacity(0.5)),
        color: Colors.orangeAccent.withOpacity(0.05),
      ),
      child: ElevatedButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TacticalMemoryScreen(
                onComplete: (results) async {
                  Navigator.pop(context, results);
                },
              ),
            ),
          );

          if (result != null) {
            final idToFetch = widget.targetPlayerId ?? widget.session.userId;

            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => const Center(child: CircularProgressIndicator(color: Colors.orangeAccent)),
            );

            try {
              await context.read<CognitiveLabProvider>().submitSession({
                'playerId': idToFetch,
                'tacticalMemory': result,
              });
              if (mounted) {
                Navigator.pop(context); // close loader
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("ÉVALUATION TACTIQUE ENREGISTRÉE 👁️"), backgroundColor: Colors.orangeAccent),
                );
              }
            } catch (e) {
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("ERREUR: $e"), backgroundColor: Colors.redAccent),
                );
              }
            }
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.orangeAccent,
          padding: const EdgeInsets.symmetric(vertical: 22),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 0,
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.remove_red_eye, size: 24),
            SizedBox(width: 12),
            Text(
              "STANDALONE TACTICAL TEST",
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionLabButtons() {
    final playerId = widget.targetPlayerId ?? widget.session.userId;
    final session = context.watch<CognitiveLabProvider>().latestSession;
    final playerName = session?.playerName ?? widget.targetPlayerName ?? 'Utilisateur';
    final playerPosition = session?.playerPosition ?? 'Joueur';

    return Row(
      children: [
        Expanded(
          child: _buildModuleButton(
            label: 'Fiche Médicale',
            icon: Icons.person_pin_outlined,
            color: const Color(0xFF3B82F6),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PlayerMedicalSheetScreen(
                  playerId: playerId,
                  playerName: playerName,
                  playerPosition: playerPosition,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildModuleButton(
            label: 'Scanner Métabolique',
            icon: Icons.biotech_outlined,
            color: const Color(0xFF10B981),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MetabolicScannerScreen(
                  playerId: playerId,
                  playerName: playerName,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModuleButton({required String label, required IconData icon, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.4)),
          color: color.withOpacity(0.06),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12, decoration: TextDecoration.none),
            ),
          ],
        ),
      ),
    );
  }
}
