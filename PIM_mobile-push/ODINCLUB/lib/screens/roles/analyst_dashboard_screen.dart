import 'package:flutter/material.dart';
import '../../user_management/models/user_management_models.dart';
import '../../ui/components/app_card.dart';
import '../../ui/components/app_section_header.dart';
import '../../ui/navigation/app_routes.dart';
import '../../ui/shell/app_shell.dart';
import '../../ui/theme/app_spacing.dart';

class AnalystDashboardScreen extends StatelessWidget {
  const AnalystDashboardScreen({super.key, required this.session});

  final SessionModel session;

  @override
  Widget build(BuildContext context) {
    final name = '${session.firstName ?? ''} ${session.lastName ?? ''}'.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionHeader(
          title: name.isEmpty ? 'Analyst Dashboard' : name,
          subtitle: 'AI match analysis summary and performance insights.',
        ),
        const SizedBox(height: AppSpacing.s24),
        Row(
          children: const [
            Expanded(
              child: _StatCard(
                label: 'Total Analyses',
                value: '24',
                icon: Icons.analytics_outlined,
              ),
            ),
            SizedBox(width: AppSpacing.s12),
            Expanded(
              child: _StatCard(
                label: 'Last Match',
                value: '2h ago',
                icon: Icons.sports_soccer,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s12),
        Row(
          children: const [
            Expanded(
              child: _StatCard(
                label: 'Players Tagged',
                value: '186',
                icon: Icons.people_outline,
              ),
            ),
            SizedBox(width: AppSpacing.s12),
            Expanded(
              child: _StatCard(
                label: 'Reports',
                value: '8',
                icon: Icons.bar_chart_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s24),
        const _ActionCard(
          title: 'Match Analysis',
          subtitle: 'Review AI analysis history and start a new run.',
          icon: Icons.video_camera_front_outlined,
          route: AppRoutes.analysis,
        ),
        const SizedBox(height: AppSpacing.s12),
        const _ActionCard(
          title: 'Performance Reports',
          subtitle: 'Player and team performance analytics.',
          icon: Icons.assessment_outlined,
          route: AppRoutes.reports,
        ),
        const SizedBox(height: AppSpacing.s12),
        const _ActionCard(
          title: 'Players',
          subtitle: 'Access player profiles and metrics.',
          icon: Icons.people_alt_outlined,
          route: AppRoutes.players,
        ),
        const SizedBox(height: AppSpacing.s12),
        const _ActionCard(
          title: 'Team Chemistry',
          subtitle: 'Affinity matrix, best pairs, and lineup chemistry score.',
          icon: Icons.hub_outlined,
          route: AppRoutes.chemistry,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.12),
            child: Icon(icon, color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: AppSpacing.s4),
                Text(value, style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
          ),
        ],
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
            radius: 22,
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
