import 'package:flutter/material.dart';
import '../../user_management/models/user_management_models.dart';
import '../../ui/components/app_card.dart';
import '../../ui/components/app_section_header.dart';
import '../../ui/navigation/app_routes.dart';
import '../../ui/shell/app_shell.dart';
import '../../ui/theme/app_spacing.dart';

class ScoutDashboardScreen extends StatelessWidget {
  const ScoutDashboardScreen({
    super.key,
    required this.session,
  });

  final SessionModel session;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSectionHeader(
          title: 'Scout Dashboard',
          subtitle: 'Liste des joueurs avec les meilleures performances et outils IA.',
        ),
        const SizedBox(height: AppSpacing.s24),
        const _ActionCard(
          title: 'Best Performances',
          subtitle: 'Parcourir la liste des joueurs.',
          icon: Icons.leaderboard,
          route: AppRoutes.players,
        ),
        const SizedBox(height: AppSpacing.s12),
        const _ActionCard(
          title: 'AI Scouting',
          subtitle: 'Campagnes et insights IA.',
          icon: Icons.psychology,
          route: AppRoutes.aiCampaigns,
        ),
      ],
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
            backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
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
