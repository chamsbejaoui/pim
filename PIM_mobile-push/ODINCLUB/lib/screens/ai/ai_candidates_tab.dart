import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:provider/provider.dart' as prov;
import '../../theme/ai_colors.dart';
import '../../providers/campaign_provider.dart';
import '../../widgets/ai/ai_player_card.dart';
import '../../widgets/ai/ai_suggestion_banner.dart';
import 'ai_player_insights_screen.dart';

/// Lists players sorted by AI match %, with suggestion banner.
class AiCandidatesTab extends StatelessWidget {
  const AiCandidatesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CampaignProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(
              child:
                  CircularProgressIndicator(color: AiColors.primary));
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
          children: [
            if (provider.error != null)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AiColors.error.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: AiColors.error.withOpacity(0.3)),
                ),
                child: Row(children: [
                  const Icon(Icons.error_outline,
                      color: AiColors.error, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(provider.error!,
                          style: const TextStyle(
                              color: AiColors.error, fontSize: 12))),
                  IconButton(
                    icon: const Icon(Icons.close,
                        color: AiColors.error, size: 18),
                    onPressed: () => provider.clearError(),
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
                ]),
              ),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Top Match Candidates',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                TextButton.icon(
                  onPressed: () => provider.loadPlayers(),
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Refresh',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  style: TextButton.styleFrom(
                      foregroundColor: AiColors.primary),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (provider.players.isEmpty && provider.error == null)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 60),
                child: Column(children: [
                  Icon(Icons.person_search,
                      size: 64, color: Colors.white.withOpacity(0.2)),
                  const SizedBox(height: 16),
                  Text('No candidates yet',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white.withOpacity(0.5))),
                  const SizedBox(height: 8),
                  Text(
                      'Add players using the + button to start scouting',
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.3))),
                ]),
              ),

            ...provider.players.map((player) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Dismissible(
                  key: Key(player.id ?? player.name),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    decoration: BoxDecoration(
                      color: AiColors.error.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.delete_outline,
                        color: AiColors.error, size: 28),
                  ),
                  confirmDismiss: (_) async {
                    return await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: AiColors.cardDark,
                            title: const Text('Delete Player',
                                style: TextStyle(color: Colors.white)),
                            content: Text(
                                'Remove ${player.name} from the database?',
                                style: const TextStyle(
                                    color: AiColors.textSecondary)),
                            actions: [
                              TextButton(
                                  onPressed: () =>
                                      Navigator.pop(ctx, false),
                                  child: const Text('Cancel')),
                              ElevatedButton(
                                onPressed: () =>
                                    Navigator.pop(ctx, true),
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: AiColors.error),
                                child: const Text('Delete',
                                    style:
                                        TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        ) ??
                        false;
                  },
                  onDismissed: (_) {
                    provider.deletePlayer(player);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('${player.name} deleted'),
                      backgroundColor: AiColors.error,
                    ));
                  },
                  child: AiPlayerCard(
                    player: player,
                    isSelected: provider.isSelected(player),
                    onToggleSelect: () =>
                        provider.togglePlayerSelection(player),
                    onTap: () {
                      // Re-inject provider so AiPlayerInsightsScreen can
                      // call context.read<CampaignProvider>() correctly
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  prov.ChangeNotifierProvider<CampaignProvider>.value(
                                    value: provider,
                                    child: AiPlayerInsightsScreen(
                                        player: player),
                                  )));
                    },
                  ),
                ),
              );
            }),

            const SizedBox(height: 8),

            if (provider.topAiSuggestion != null)
              AiSuggestionBanner(
                message:
                    '${provider.topAiSuggestion!.name} has a '
                    '${provider.topAiSuggestion!.matchPercentage?.round() ?? 0}% '
                    'tactical fit'
                    '${provider.topAiSuggestion!.clusterProfile != null ? " — ${provider.topAiSuggestion!.clusterProfile} profile" : ""}.',
              ),
          ],
        );
      },
    );
  }
}
