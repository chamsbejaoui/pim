import 'package:flutter/material.dart';
import '../components/app_card.dart';
import '../components/app_section_header.dart';
import '../navigation/app_routes.dart';
import '../shell/app_shell.dart';
import '../theme/app_spacing.dart';

class AdminOverviewScreen extends StatelessWidget {
  const AdminOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSectionHeader(
          title: 'Admin Dashboard',
          subtitle: 'Vue globale des clubs, utilisateurs et approvals.',
        ),
        const SizedBox(height: AppSpacing.s24),
        Wrap(
          spacing: AppSpacing.s12,
          runSpacing: AppSpacing.s12,
          children: const [
            _StatCard(title: 'Utilisateurs actifs', value: '—', icon: Icons.people_alt_outlined),
            _StatCard(title: 'Clubs actifs', value: '—', icon: Icons.shield_outlined),
            _StatCard(title: 'Approvals en attente', value: '—', icon: Icons.pending_actions_outlined),
            _StatCard(title: 'Alertes IA', value: '—', icon: Icons.auto_awesome_outlined),
          ],
        ),
        const SizedBox(height: AppSpacing.s24),
        const AppSectionHeader(
          title: 'Raccourcis',
          subtitle: 'Acceder rapidement aux modules admin.',
        ),
        const SizedBox(height: AppSpacing.s12),
        _ActionCard(
          title: 'Gestion des utilisateurs',
          subtitle: 'Liste + filtres + approvals.',
          icon: Icons.manage_accounts_outlined,
          route: AppRoutes.adminUsers,
        ),
        const SizedBox(height: AppSpacing.s12),
        _ActionCard(
          title: 'Audit log',
          subtitle: 'Historique des actions sensibles.',
          icon: Icons.receipt_long_outlined,
          route: AppRoutes.auditLog,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: AppCard(
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
              child: Icon(icon, color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(width: AppSpacing.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: AppSpacing.s4),
                  Text(title, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
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
      onTap: () => shell?.navigate(route),
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
