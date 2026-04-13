import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cognitive_lab_provider.dart';
import '../../../theme/app_theme.dart';
import '../../../../user_management/models/user_management_models.dart';
import 'cognitive_dashboard_screen.dart';

class SquadCognitiveOverviewScreen extends StatefulWidget {
  final SessionModel session;
  const SquadCognitiveOverviewScreen({super.key, required this.session});

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Consumer<CognitiveLabProvider>(
        builder: (context, provider, child) {
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
            child: SafeArea(
              child: RefreshIndicator(
                onRefresh: () => provider.fetchSquadOverview(),
                color: Colors.cyanAccent,
                backgroundColor: const Color(0xFF1E293B),
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    _buildAppBar(),
                    if (provider.isLoading)
                      const SliverFillRemaining(
                        child: Center(child: CircularProgressIndicator(color: Colors.cyanAccent)),
                      )
                    else ...[
                      _buildSummaryStats(provider),
                      _buildAtRiskSection(provider),
                      _buildRecentSessionsHeader(),
                      _buildRecentSessionsList(provider),
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

  Widget _buildAppBar() {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      pinned: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'VUE ÉQUIPE COGNITIVE',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          letterSpacing: 2,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildSummaryStats(CognitiveLabProvider provider) {
    final summary = provider.squadSummary;
    final readiness = summary['avgReadiness'] ?? 0.0;
    
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B).withOpacity(0.6),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.cyanAccent.withOpacity(0.1)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.cyanAccent.withOpacity(0.05),
                    blurRadius: 20,
                    spreadRadius: 2,
                  )
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'PRÉPARATION GLOBALE',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 120,
                        height: 120,
                        child: CircularProgressIndicator(
                          value: readiness / 100,
                          strokeWidth: 10,
                          backgroundColor: Colors.white.withOpacity(0.05),
                          valueColor: AlwaysStoppedAnimation(
                            readiness > 70 ? Colors.cyanAccent : Colors.orangeAccent,
                          ),
                        ),
                      ),
                      Text(
                        '${readiness.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMiniStat('FOCUS', '${summary['avgFocus'] ?? 0}%'),
                      _buildMiniStat('MÉMOIRE', '${summary['avgMemory'] ?? 0}%'),
                      _buildMiniStat('RÉACTION', '${summary['avgReaction'] ?? 0}ms'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFF64748B), fontSize: 8, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 0.5),
        ),
      ],
    );
  }

  Widget _buildAtRiskSection(CognitiveLabProvider provider) {
    if (provider.atRiskPlayers.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent, size: 18),
                SizedBox(width: 8),
                Text(
                  'ALERTES DE FATIGUE CRITIQUE',
                  style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.w900, letterSpacing: 1.2, fontSize: 12),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: provider.atRiskPlayers.length,
              itemBuilder: (context, index) {
                final player = provider.atRiskPlayers[index];
                return GestureDetector(
                  onTap: () => _navigateToPlayerLab(player['id'], player['name']),
                  child: Container(
                    width: 100,
                    margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.white.withOpacity(0.1),
                          child: const Icon(Icons.person, color: Colors.white, size: 20),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          player['name'] ?? 'Joueur',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${player['readiness'] ?? 0}% Ready',
                          style: const TextStyle(color: Colors.redAccent, fontSize: 8, fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSessionsHeader() {
    return const SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
        child: Text(
          'Derniers Tests Effectués',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildRecentSessionsList(CognitiveLabProvider provider) {
    if (provider.allSessions.isEmpty) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Text('Aucune session récente.', style: TextStyle(color: Color(0xFF64748B))),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final session = provider.allSessions[index];
          final readiness = session['readinessScore'] ?? 0;
          
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B).withOpacity(0.4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              onTap: () => _navigateToPlayerLab(session['playerId'], session['playerName']),
              leading: CircleAvatar(
                backgroundColor: Colors.cyanAccent.withOpacity(0.1),
                child: const Icon(Icons.psychology, color: Colors.cyanAccent, size: 20),
              ),
              title: Text(
                session['playerName'] ?? 'Joueur Inconnu',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                'Test: ${session['testType'] ?? 'N/A'} • ${session['timeAgo'] ?? 'Instant'}',
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$readiness%',
                    style: TextStyle(
                      color: readiness > 70 ? Colors.cyanAccent : Colors.orangeAccent,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                  const Text(
                    'READY',
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 8, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ),
          );
        },
        childCount: provider.allSessions.length,
      ),
    );
  }

  void _navigateToPlayerLab(String? playerId, String? playerName) {
    if (playerId == null) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CognitiveDashboardScreen(
          session: widget.session,
          targetPlayerId: playerId,
          targetPlayerName: playerName,
        ),
      ),
    );
  }
}
