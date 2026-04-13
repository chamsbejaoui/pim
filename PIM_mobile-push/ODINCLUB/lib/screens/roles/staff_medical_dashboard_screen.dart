import 'package:flutter/material.dart';
import '../../models/player_model.dart';
import '../../services/player_service.dart';
import '../../user_management/models/user_management_models.dart';
import '../../ui/components/app_card.dart';
import '../../ui/components/app_section_header.dart';
import '../../ui/navigation/app_routes.dart';
import '../../ui/shell/app_shell.dart';
import '../../ui/theme/app_spacing.dart';
import '../../ui/theme/medical_theme.dart';

class StaffMedicalDashboardScreen extends StatefulWidget {
  const StaffMedicalDashboardScreen({super.key, required this.session});

  final SessionModel session;

  @override
  State<StaffMedicalDashboardScreen> createState() =>
      _StaffMedicalDashboardScreenState();
}

class _StaffMedicalDashboardScreenState
    extends State<StaffMedicalDashboardScreen> {
  final PlayerService _playerService = PlayerService();
  late Future<List<PlayerModel>> _playersFuture;
  final Set<String> _clearing = {};

  @override
  void initState() {
    super.initState();
    _playersFuture = _playerService.fetchPlayers();
  }

  Future<void> _refreshPlayers() async {
    setState(() {
      _playersFuture = _playerService.fetchPlayers();
    });
    await _playersFuture;
  }

  Future<void> _clearMedical(PlayerModel player) async {
    setState(() {
      _clearing.add(player.id);
    });
    try {
      await _playerService.clearMedical(player.id);
      await _refreshPlayers();
    } finally {
      if (!mounted) {
        return;
      }
      setState(() {
        _clearing.remove(player.id);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final name = '${session.firstName ?? ''} ${session.lastName ?? ''}'.trim();
    return MedicalThemeScope(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSectionHeader(
              title: name.isEmpty ? 'Staff Medical' : name,
              subtitle: 'Suivi medical et prevention des blessures.',
            ),
            const SizedBox(height: AppSpacing.s24),
            const _ActionCard(
              title: 'Analyse medicale',
              subtitle: 'Selectionner un joueur pour analyser.',
              icon: Icons.monitor_heart,
              route: AppRoutes.medicalPlayers,
            ),
            const SizedBox(height: AppSpacing.s12),
            const _ActionCard(
              title: 'Simulation de match',
              subtitle: 'Simuler blessures et charge.',
              icon: Icons.sports_soccer,
              route: AppRoutes.medicalSimulation,
            ),
            const SizedBox(height: AppSpacing.s12),
            const _ActionCard(
              title: 'Calendrier de recuperation',
              subtitle: 'Suivre les dates de retour estimees.',
              icon: Icons.calendar_month,
              route: AppRoutes.medicalRecoveryCalendar,
            ),
            const SizedBox(height: AppSpacing.s12),
            const _ActionCard(
              title: 'Historique des matchs',
              subtitle: 'Consulter les simulations deja jouees.',
              icon: Icons.history_rounded,
              route: AppRoutes.medicalMatchHistory,
            ),
            const SizedBox(height: AppSpacing.s16),
            Row(
              children: [
                Text(
                  'Injured players',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Refresh',
                  onPressed: _refreshPlayers,
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s8),
            FutureBuilder<List<PlayerModel>>(
              future: _playersFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError) {
                  return Text(
                    'Unable to load injured players.',
                    style: Theme.of(context).textTheme.bodySmall,
                  );
                }
                final players = snapshot.data ?? [];
                final injured = players
                    .where((p) => p.isInjured == true)
                    .toList();
                if (injured.isEmpty) {
                  return Text(
                    'No injured players right now.',
                    style: Theme.of(context).textTheme.bodySmall,
                  );
                }

                return AppCard(
                  child: SizedBox(
                    height: 260,
                    child: ListView.separated(
                      itemCount: injured.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final player = injured[index];
                        final isBusy = _clearing.contains(player.id);
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: MedicalTheme.surfaceAlt.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: MedicalTheme.cardBorder.withOpacity(0.9),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      player.name,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      player.lastInjuryType ?? 'Injured',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: MedicalTheme.textSecondary,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: isBusy
                                    ? null
                                    : () => _clearMedical(player),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: MedicalTheme.danger
                                      .withOpacity(0.12),
                                  foregroundColor: MedicalTheme.danger,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                      color: MedicalTheme.danger.withOpacity(
                                        0.35,
                                      ),
                                    ),
                                  ),
                                  textStyle: Theme.of(context)
                                      .textTheme
                                      .labelLarge
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                child: isBusy
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text('Clear'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.route,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String route;

  @override
  Widget build(BuildContext context) {
    final shell = AppShellScope.of(context);
    return AppCard(
      onTap: () {
        if (shell != null) {
          shell.navigate(route);
        } else {
          Navigator.of(context).pushNamed(route);
        }
      },
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.12),
            child: Icon(icon, color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(width: AppSpacing.s16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: AppSpacing.s4),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
