import 'package:flutter/material.dart';
import '../../models/player_model.dart';
import '../../services/player_service.dart';
import '../../ui/components/app_button.dart';
import '../../ui/components/app_card.dart';
import '../../ui/components/app_section_header.dart';
import '../../ui/components/empty_state.dart';
import '../../ui/components/loading_state.dart';
import '../../ui/theme/app_spacing.dart';
import '../../ui/theme/medical_theme.dart';
import 'medical_analysis_screen.dart';

class MedicalPlayersScreen extends StatefulWidget {
  const MedicalPlayersScreen({super.key});

  @override
  State<MedicalPlayersScreen> createState() => _MedicalPlayersScreenState();
}

class _MedicalPlayersScreenState extends State<MedicalPlayersScreen> {
  final PlayerService _playerService = PlayerService();
  late Future<List<PlayerModel>> _playersFuture;

  @override
  void initState() {
    super.initState();
    _playersFuture = _playerService.fetchPlayers();
  }

  Future<void> _refresh() async {
    setState(() {
      _playersFuture = _playerService.fetchPlayers();
    });
  }

  void _openPlayer(PlayerModel player) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => MedicalAnalysisScreen(player: player)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MedicalThemeScope(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionHeader(
            title: 'Medical Players',
            subtitle: 'Track injury risk, fatigue, and recovery status.',
          ),
          const SizedBox(height: AppSpacing.s16),
          Expanded(
            child: FutureBuilder<List<PlayerModel>>(
              future: _playersFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LoadingState(message: 'Loading players...');
                }
                if (snapshot.hasError) {
                  return EmptyState(
                    title: 'Unable to load players',
                    message: 'Please check your connection and try again.',
                    action: AppButton(label: 'Retry', onPressed: _refresh),
                  );
                }

                final players = snapshot.data ?? const [];
                if (players.isEmpty) {
                  return EmptyState(
                    title: 'No players available',
                    message:
                        'Create or sync players to start medical tracking.',
                    action: AppButton(label: 'Refresh', onPressed: _refresh),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView.separated(
                    padding: EdgeInsets.zero,
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: players.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.s12),
                    itemBuilder: (context, index) {
                      final player = players[index];
                      return AppCard(
                        onTap: () => _openPlayer(player),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: MedicalTheme.accentBlue
                                  .withValues(alpha: 0.16),
                              child: const Icon(
                                Icons.person,
                                color: MedicalTheme.primaryBlue,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.s16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    player.name,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                ],
                              ),
                            ),
                            if (player.isInjured == true)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.s8,
                                  vertical: AppSpacing.s4,
                                ),
                                decoration: BoxDecoration(
                                  color: MedicalTheme.danger.withValues(
                                    alpha: 0.12,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: MedicalTheme.danger.withValues(
                                      alpha: 0.4,
                                    ),
                                  ),
                                ),
                                child: const Text(
                                  'Injured',
                                  style: TextStyle(
                                    color: MedicalTheme.danger,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
