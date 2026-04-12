import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/cognitive_lab_provider.dart';
import '../../../../ui/shell/app_shell.dart';
import 'cognitive_dashboard_screen.dart';

class SquadCognitiveOverviewScreen extends StatefulWidget {
  const SquadCognitiveOverviewScreen({super.key});

  @override
  State<SquadCognitiveOverviewScreen> createState() => _SquadCognitiveOverviewScreenState();
}

class _SquadCognitiveOverviewScreenState extends State<SquadCognitiveOverviewScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CognitiveLabProvider>().fetchSquadOverview();
    });
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
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
        title: const Text('SQUAD RISK OVERVIEW', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 16)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () {
            final shell = AppShellScope.of(context);
            if (shell != null) {
              shell.goBack();
            } else {
              Navigator.of(context).maybePop();
            }
          },
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Consumer<CognitiveLabProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator(color: Colors.cyanAccent));
          }

          final summary = provider.squadSummary;
          final atRisk = provider.atRiskPlayers;
          final totalTests = summary.values
              .whereType<num>()
              .fold<int>(0, (acc, v) => acc + v.toInt());

          if (summary.isEmpty || totalTests == 0) {
            return const Center(child: Text('NO DATA FOR TODAY', style: TextStyle(color: Colors.white24, fontWeight: FontWeight.w900, letterSpacing: 2)));
          }

          return Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.5),
                radius: 1.5,
                colors: [
                  const Color(0xFF1E293B).withOpacity(0.5),
                  const Color(0xFF0F172A),
                ],
              ),
            ),
            child: RefreshIndicator(
              onRefresh: () => provider.fetchSquadOverview(),
              color: Colors.cyanAccent,
              backgroundColor: const Color(0xFF1E293B),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(left: 20, right: 20, top: 120, bottom: 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildOverviewCard(summary, totalTests),
                    const SizedBox(height: 40),
                    if (atRisk.isNotEmpty) ...[
                      Row(
                        children: [
                          const Icon(Icons.emergency_outlined, color: Colors.redAccent, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'AT-RISK PLAYERS (${atRisk.length})',
                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 2),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ...atRisk.map((player) => _buildPlayerCard(context, player)),
                      const SizedBox(height: 40),
                    ],
                    
                    Row(
                      children: [
                        const Icon(Icons.history_toggle_off, color: Colors.cyanAccent, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'COMPLETED ASSESSMENTS (${provider.allSessions.length})',
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 2),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (provider.allSessions.isEmpty)
                      _buildAllClearCard()
                    else
                      ...provider.allSessions.map((player) => _buildPlayerCard(context, player)),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOverviewCard(Map<String, dynamic> summary, int total) {
    List<PieChartSectionData> sections = [];
    
    summary.forEach((key, value) {
      if (value > 0) {
        final color = _getStatusColor(key);
        sections.add(
          PieChartSectionData(
            color: color,
            value: (value as int).toDouble(),
            title: '',
            radius: 20,
            badgeWidget: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: Text('$value', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
            badgePositionPercentageOffset: 1.3,
          ),
        );
      }
    });

    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Column(
            children: [
              const Text(
                "SQUAD READINESS",
                style: TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 4),
              ),
              const SizedBox(height: 32),
              SizedBox(
                height: 180,
                child: Stack(
                  children: [
                    PieChart(
                      PieChartData(
                        sectionsSpace: 4,
                        centerSpaceRadius: 65,
                        sections: sections,
                      ),
                    ),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$total',
                            style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w900),
                          ),
                          const Text(
                            'PLAYERS TESTED',
                            style: TextStyle(color: Colors.white24, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 2),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Wrap(
                spacing: 20,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: summary.entries.where((e) => e.value > 0).map((e) {
                  final color = _getStatusColor(e.key);
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: color.withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                        const SizedBox(width: 8),
                        Text(e.key.toUpperCase(), style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAllClearCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.cyanAccent.withOpacity(0.02),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.cyanAccent.withOpacity(0.1)),
      ),
      child: const Column(
        children: [
          Icon(Icons.verified_user_outlined, color: Colors.cyanAccent, size: 48),
          SizedBox(height: 16),
          Text('OPTIMAL READINESS', style: TextStyle(color: Colors.cyanAccent, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 2)),
          SizedBox(height: 4),
          Text('No players flagged for cognitive fatigue.', style: TextStyle(color: Colors.white24, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildPlayerCard(BuildContext context, Map<String, dynamic> player) {
    final statusColor = _getStatusColor(player['status']);
    
    return GestureDetector(
      onTap: () {
        final session = AppShellScope.of(context)?.session;
        if (session != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CognitiveDashboardScreen(
                session: session,
                targetPlayerId: player['playerId'],
                targetPlayerName: player['playerName'], 
                isReadOnly: false,
              ),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: statusColor.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            // Avatar (Initials)
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [statusColor.withOpacity(0.2), statusColor.withOpacity(0.05)]),
                shape: BoxShape.circle,
                border: Border.all(color: statusColor.withOpacity(0.3)),
              ),
              child: Center(
                child: Text(
                  (player['playerName'] as String?)?.isNotEmpty == true ? player['playerName'][0] : "P",
                  style: TextStyle(color: statusColor, fontSize: 18, fontWeight: FontWeight.w900),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        player['playerName']?.toUpperCase() ?? 'PLAYER PROFILE',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                        child: Text(
                          player['status'].toUpperCase(),
                          style: TextStyle(color: statusColor, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        'READINESS: ${player['mentalScore']?.toStringAsFixed(0) ?? "N/A"}%',
                        style: TextStyle(color: statusColor, fontSize: 18, fontWeight: FontWeight.w900),
                      ),
                      const Spacer(),
                      Text(
                        player['playerPosition'] ?? '',
                        style: const TextStyle(color: Colors.white10, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    player['recommendation'],
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white38, fontSize: 10, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.arrow_forward_ios, color: Colors.white10, size: 14),
          ],
        ),
      ),
    );
  }
}
