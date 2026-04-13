import 'package:flutter/material.dart';
import '../../user_management/models/user_management_models.dart';
import '../../ui/components/app_card.dart';
import '../../ui/components/app_section_header.dart';
import '../../ui/navigation/app_routes.dart';
import '../../ui/shell/app_shell.dart';
import '../../ui/theme/app_spacing.dart';

class JoueurDashboardScreen extends StatelessWidget {
  const JoueurDashboardScreen({
    super.key,
    required this.session,
  });

  final SessionModel session;

  @override
  Widget build(BuildContext context) {
    final displayName = '${session.firstName ?? ''} ${session.lastName ?? ''}'.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionHeader(
          title: displayName.isEmpty ? 'Bienvenue' : 'Bienvenue $displayName',
          subtitle: 'Votre tableau de bord joueur est actif.',
        ),
        const SizedBox(height: AppSpacing.s24),
        const _InfoCard(
          title: 'Programme du jour',
          subtitle: 'Consultez vos objectifs et charge d’entrainement.',
          icon: Icons.fitness_center,
        ),
        const SizedBox(height: AppSpacing.s12),
        const _InfoCard(
          title: 'Etat physique',
          subtitle: 'Suivez votre forme et votre recuperation.',
          icon: Icons.health_and_safety,
        ),
        const SizedBox(height: AppSpacing.s12),
        _InfoCard(
          title: 'Labo Cognitif IA',
          subtitle: 'Evaluez votre fatigue mentale avant de vous entrainer.',
          icon: Icons.psychology_outlined,
          onTap: () {
            final shell = AppShellScope.of(context);
            if (shell != null) {
              shell.navigate(AppRoutes.cognitiveDashboard);
            } else {
              Navigator.of(context).pushNamed(AppRoutes.cognitiveDashboard);
            }
          },
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
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
