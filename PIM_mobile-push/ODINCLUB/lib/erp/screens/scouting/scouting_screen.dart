import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../providers/players_provider.dart';

class ScoutingScreen extends StatefulWidget {
  const ScoutingScreen({super.key});

  @override
  State<ScoutingScreen> createState() => _ScoutingScreenState();
}

class _ScoutingScreenState extends State<ScoutingScreen> {
  String? _filterPosition;

  @override
  void initState() {
    super.initState();
    Provider.of<PlayersProvider>(context, listen: false).fetchPlayers(isProspect: true);
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PlayersProvider>(context);
    final prospects = provider.players.where((p) => p.isProspect == true).toList();

    return Scaffold(
      backgroundColor: OdinTheme.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'RECRUTEMENT',
              style: TextStyle(
                color: OdinTheme.textTertiary,
                fontSize: 10,
                letterSpacing: 2,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Text('Scouting & Intelligence'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded),
            onPressed: _showFilters,
          ),
        ],
      ),
      body: Column(
        children: [
          // ─── Filter chips ────────────────────────────
          if (_filterPosition != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Chip(
                    label: Text(_filterPosition!),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () {
                      setState(() => _filterPosition = null);
                      provider.fetchPlayers(isProspect: true);
                    },
                  ),
                ],
              ),
            ),

          // ─── List of Prospects ─────────────────────
          Expanded(
            child: provider.isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: OdinTheme.primaryBlue))
                : prospects.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.radar_rounded,
                                size: 64, color: OdinTheme.textTertiary),
                            const SizedBox(height: 16),
                            const Text(
                              'Aucun prospect trouvé',
                              style: TextStyle(color: OdinTheme.textTertiary),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: prospects.length,
                        itemBuilder: (context, i) => _buildProspectCard(prospects[i]),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildProspectCard(dynamic player) {
    return GestureDetector(
      onTap: () => context.push('/players/detail', extra: player.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: OdinTheme.glassCard,
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: OdinTheme.primaryBlue.withValues(alpha: 0.2),
                  child: Text(
                    player.initials,
                    style: const TextStyle(
                      color: OdinTheme.primaryBlue,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        player.fullName,
                        style: const TextStyle(
                          color: OdinTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${player.position} • ${player.nationality ?? 'Inconnu'}',
                        style: const TextStyle(
                          color: OdinTheme.textTertiary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (player.aiScore != null)
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: OdinTheme.primaryBlue.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: OdinTheme.primaryBlue.withValues(alpha: 0.4)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '${player.aiScore}',
                          style: const TextStyle(
                            color: OdinTheme.primaryBlue,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Text(
                          'AI SCORE',
                          style: TextStyle(
                            color: OdinTheme.primaryBlue,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            if (player.stats != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Divider(color: OdinTheme.cardBorder),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: (player.stats as Map<String, dynamic>).entries.take(3).map((e) {
                  return Column(
                    children: [
                      Text(
                        '${e.value}',
                        style: const TextStyle(
                          color: OdinTheme.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        e.key.replaceAll('_', ' ').toUpperCase(),
                        style: const TextStyle(
                          color: OdinTheme.textTertiary,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ]
          ],
        ),
      ),
    );
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      backgroundColor: OdinTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filtres (Poste)',
                style: TextStyle(
                  color: OdinTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: ['Gardien', 'Défenseur', 'Milieu', 'Attaquant']
                    .map((p) => ChoiceChip(
                          label: Text(p),
                          selected: _filterPosition == p,
                          selectedColor: OdinTheme.primaryBlue,
                          onSelected: (sel) {
                            setState(() => _filterPosition = sel ? p : null);
                            Provider.of<PlayersProvider>(context, listen: false)
                                .fetchPlayers(
                              isProspect: true,
                              position: _filterPosition,
                            );
                            Navigator.pop(ctx);
                          },
                        ))
                    .toList(),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}
