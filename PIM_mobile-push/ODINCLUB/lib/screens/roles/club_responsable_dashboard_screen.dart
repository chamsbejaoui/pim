import 'package:flutter/material.dart';
import '../../user_management/models/user_management_models.dart';
import '../../ui/components/app_card.dart';
import '../../ui/components/app_section_header.dart';
import '../../ui/theme/app_colors.dart';
import '../../ui/theme/app_spacing.dart';
import '../../ui/navigation/app_routes.dart';
import '../../ui/shell/app_shell.dart';

class ClubResponsableDashboardScreen extends StatelessWidget {
  const ClubResponsableDashboardScreen({super.key, required this.session});

  final SessionModel session;

  @override
  Widget build(BuildContext context) {
    final name = '${session.firstName ?? ''} ${session.lastName ?? ''}'.trim();
    final clubLabel = session.clubName == null || session.clubName!.isEmpty
        ? 'Club'
        : session.clubName!;
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: AppSpacing.s24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(
            title: name.isEmpty ? 'Responsable Club' : name,
            subtitle: '$clubLabel • Responsable club',
          ),
          const SizedBox(height: AppSpacing.s24),
          const _SummaryCard(),
          const SizedBox(height: AppSpacing.s16),
          const _TrendCard(),
          const SizedBox(height: AppSpacing.s12),
          Row(
            children: const [
              Expanded(
                child: _MiniStatCard(
                  title: 'Salaires',
                  subtitle: '85% payes',
                  icon: Icons.payments_outlined,
                  accent: AppColors.success,
                ),
              ),
              SizedBox(width: AppSpacing.s12),
              Expanded(
                child: _MiniStatCard(
                  title: 'Sponsors',
                  subtitle: '12 actifs',
                  icon: Icons.handshake_outlined,
                  accent: AppColors.primaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s12),
          Row(
            children: const [
              Expanded(
                child: _MiniStatCard(
                  title: 'Transfers',
                  subtitle: '4 en cours',
                  icon: Icons.swap_horiz_outlined,
                  accent: AppColors.warning,
                ),
              ),
              SizedBox(width: AppSpacing.s12),
              Expanded(
                child: _MiniStatCard(
                  title: 'Tresorerie',
                  subtitle: 'Saine',
                  icon: Icons.account_balance_outlined,
                  accent: AppColors.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s16),
          _ActionTile(
            title: 'Validations utilisateurs',
            subtitle: 'Approuver ou refuser les membres.',
            icon: Icons.verified_user_outlined,
            route: AppRoutes.approvals,
          ),
          const SizedBox(height: AppSpacing.s12),
          _ActionTile(
            title: 'Communication interne',
            subtitle: 'Acceder aux messages et alertes.',
            icon: Icons.forum_outlined,
            route: AppRoutes.communication,
          ),
          const SizedBox(height: AppSpacing.s12),
          _ActionTile(
            title: 'Labo Cognitif IA',
            subtitle: 'Surveiller la charge mentale de l\'equipe.',
            icon: Icons.psychology_outlined,
            route: AppRoutes.squadCognitiveOverview,
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard();

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Solde Total', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: AppSpacing.s8),
          Text(
            '12,450.00 DT',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppSpacing.s12),
          Row(
            children: [
              _DeltaChip(
                label: 'Revenus',
                value: '+4,200 DT',
                icon: Icons.trending_up_rounded,
                color: AppColors.success,
              ),
              const SizedBox(width: AppSpacing.s12),
              _DeltaChip(
                label: 'Depenses',
                value: '-1,850 DT',
                icon: Icons.trending_down_rounded,
                color: AppColors.danger,
              ),
              const Spacer(),
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DeltaChip extends StatelessWidget {
  const _DeltaChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: AppSpacing.s8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodySmall),
              Text(
                value,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TrendCard extends StatelessWidget {
  const _TrendCard();

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Tendances Budgetaires',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              Text(
                'Voir tout',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: primary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s16),
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _Bar(value: 0.4),
                _Bar(value: 0.55),
                _Bar(value: 0.9, active: true),
                _Bar(value: 0.6),
                _Bar(value: 0.35),
                _Bar(value: 0.5),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              _MonthLabel('Jan'),
              _MonthLabel('Feb'),
              _MonthLabel('Mar'),
              _MonthLabel('Apr'),
              _MonthLabel('May'),
              _MonthLabel('Jun'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.value, this.active = false});

  final double value;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final height = 100 * value;
    final primary = Theme.of(context).colorScheme.primary;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: height,
            decoration: BoxDecoration(
              color: active ? primary : AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}

class _MonthLabel extends StatelessWidget {
  const _MonthLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(
        context,
      ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  const _MiniStatCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accent, size: 20),
          ),
          const SizedBox(width: AppSpacing.s12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: AppSpacing.s4),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
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
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
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
          const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
        ],
      ),
    );
  }
}
