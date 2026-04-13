import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/ai_colors.dart';
import '../../providers/campaign_provider.dart';
import 'ai_player_insights_screen.dart';
import 'package:provider/provider.dart' as prov;

/// Shows archived (non-recruited) players from past sessions.
class AiArchiveTab extends StatelessWidget {
  const AiArchiveTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CampaignProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(
              child: CircularProgressIndicator(color: AiColors.primary));
        }

        final archived = provider.archivedPlayers;

        if (archived.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.archive_outlined,
                    size: 64, color: Colors.white.withOpacity(0.2)),
                const SizedBox(height: 16),
                Text('No archived players',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white.withOpacity(0.5))),
                const SizedBox(height: 8),
                Text(
                    'Players not recruited at end of session\nwill appear here',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.3))),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
          itemCount: archived.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(children: [
                  const Icon(Icons.archive_outlined,
                      color: AiColors.textSecondary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                      '${archived.length} Archived Player${archived.length != 1 ? 's' : ''}',
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                ]),
              );
            }

            final player = archived[index - 1];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => prov.ChangeNotifierProvider<CampaignProvider>.value(
                        value: provider,
                        child: AiPlayerInsightsScreen(player: player),
                      ),
                    ),
                  );
                },
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AiColors.glassBackground,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AiColors.glassBorder),
                    ),
                    child: Row(children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: AiColors.cardDark,
                        child: Text(
                          player.name.isNotEmpty
                              ? player.name[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(player.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: Colors.white)),
                            const SizedBox(height: 3),
                            Text(player.club ?? 'Unknown Club',
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AiColors.textSecondary)),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.speed,
                                size: 14,
                                color:
                                    AiColors.primary.withOpacity(0.7)),
                            const SizedBox(width: 4),
                            Text('${player.speed.round()}',
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AiColors.textSecondary)),
                          ]),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AiColors.error.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('ARCHIVED',
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                    color: AiColors.error)),
                          ),
                        ],
                      ),
                    ]),
                  ),
                ),
              ),
              ),
            );
          },
        );
      },
    );
  }
}
