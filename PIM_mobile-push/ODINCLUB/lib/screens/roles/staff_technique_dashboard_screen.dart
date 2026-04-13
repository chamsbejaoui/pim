import 'package:flutter/material.dart';
import '../../user_management/models/user_management_models.dart';
import '../../ui/components/app_card.dart';
import '../../ui/components/app_section_header.dart';
import '../../ui/navigation/app_routes.dart';
import '../../ui/shell/app_shell.dart';
import '../../ui/theme/app_spacing.dart';

class StaffTechniqueDashboardScreen extends StatelessWidget {
  const StaffTechniqueDashboardScreen({
    super.key,
    required this.session,
  });

  final SessionModel session;

  @override
  Widget build(BuildContext context) {
    final name = '${session.firstName ?? ''} ${session.lastName ?? ''}'.trim();
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: AppSpacing.s24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(
            title: name.isEmpty ? 'Staff Technique' : name,
            subtitle: 'Analyse et performance de l\'equipe.',
          ),
          const SizedBox(height: AppSpacing.s24),
          const _ActionCard(
            title: 'Analyse Match',
            subtitle: 'Video + IA + insights.',
            icon: Icons.analytics,
            route: AppRoutes.analysis,
          ),
          const SizedBox(height: AppSpacing.s12),
          const _ActionCard(
            title: 'Planification de Saison',
            subtitle: 'Generer la saison avec l\'IA.',
            icon: Icons.calendar_month,
            route: AppRoutes.seasonPlanning,
          ),
          const SizedBox(height: AppSpacing.s12),
          const _ActionCard(
            title: 'Analyse Tactique & Adversaire',
            subtitle: 'Generer un XI de depart sur-mesure (IA).',
            icon: Icons.sports_soccer,
            route: AppRoutes.tactics,
          ),
          const SizedBox(height: AppSpacing.s12),
          const _ActionCard(
            title: 'Chemie d\'Equipe',
            subtitle: 'Matrice d\'affinites, conflits et score du XI.',
            icon: Icons.hub_outlined,
            route: AppRoutes.chemistry,
          ),
          const SizedBox(height: AppSpacing.s12),
          const _ActionCard(
            title: 'Calendrier & Charge',
            subtitle: 'Planifier les seances et matches.',
            icon: Icons.calendar_month,
            route: AppRoutes.calendar,
          ),
          const SizedBox(height: AppSpacing.s12),
          const _ActionCard(
            title: 'Joueurs',
            subtitle: 'Suivi de l\'effectif et stats.',
            icon: Icons.people_alt,
            route: AppRoutes.players,
          ),
          const SizedBox(height: AppSpacing.s12),
          const _ActionCard(
            title: 'Tests & Rapports',
            subtitle: 'Performance et evaluations.',
            icon: Icons.assessment,
            route: AppRoutes.reports,
          ),
          const SizedBox(height: AppSpacing.s12),
          const _ActionCard(
            title: 'Bibliotheque d\'exercices',
            subtitle: 'Exercices et modeles d\'entrainement.',
            icon: Icons.menu_book,
            route: AppRoutes.exercises,
          ),
          const SizedBox(height: AppSpacing.s12),
          const _ActionCard(
            title: 'Tests physiques',
            subtitle: 'Creer et gerer les tests.',
            icon: Icons.sports,
            route: AppRoutes.tests,
          ),
          const SizedBox(height: AppSpacing.s12),
          const _ActionCard(
            title: 'Labo Cognitif IA',
            subtitle: 'Evaluer la fatigue mentale des joueurs.',
            icon: Icons.psychology_outlined,
            route: AppRoutes.squadCognitiveOverview,
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
