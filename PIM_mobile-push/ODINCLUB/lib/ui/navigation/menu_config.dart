import 'package:flutter/material.dart';
import '../../utils/role_mapper.dart';
import 'app_routes.dart';

class MenuItemConfig {
  const MenuItemConfig({
    required this.title,
    required this.icon,
    required this.route,
  });

  final String title;
  final IconData icon;
  final String route;
}

class MenuConfig {
  MenuConfig._();

  static String defaultRouteForRole(String role) {
    final roleCode = RoleMapper.normalize(role);
    switch (roleCode) {
      case RoleMapper.admin:
        return AppRoutes.adminDashboard;
      case RoleMapper.clubResponsable:
        return AppRoutes.clubDashboard;
      case RoleMapper.analyst:
        return AppRoutes.analystDashboard;
      case RoleMapper.staffTechnique:
        return AppRoutes.coachDashboard;
      case RoleMapper.staffMedical:
        return AppRoutes.medicalDashboard;
      case RoleMapper.finance:
        return AppRoutes.financeDashboard;
      case RoleMapper.scout:
        return AppRoutes.scoutDashboard;
      case RoleMapper.player:
      default:
        return AppRoutes.playerDashboard;
    }
  }

  static List<MenuItemConfig> itemsForRole(String role) {
    final roleCode = RoleMapper.normalize(role);
    switch (roleCode) {
      case RoleMapper.admin:
        return const [
          MenuItemConfig(
            title: 'Dashboard',
            icon: Icons.grid_view_rounded,
            route: AppRoutes.adminDashboard,
          ),
          MenuItemConfig(
            title: 'Communication',
            icon: Icons.forum_outlined,
            route: AppRoutes.communication,
          ),
          MenuItemConfig(
            title: 'Players',
            icon: Icons.people_outline,
            route: AppRoutes.players,
          ),
          MenuItemConfig(
            title: 'Reports',
            icon: Icons.analytics_outlined,
            route: AppRoutes.reports,
          ),
          MenuItemConfig(
            title: 'Team Chemistry',
            icon: Icons.hub_outlined,
            route: AppRoutes.chemistry,
          ),
        ];
      case RoleMapper.clubResponsable:
        return const [
          MenuItemConfig(
            title: 'Club Dashboard',
            icon: Icons.home_outlined,
            route: AppRoutes.clubDashboard,
          ),
          MenuItemConfig(
            title: 'User Approvals',
            icon: Icons.verified_user_outlined,
            route: AppRoutes.approvals,
          ),
          MenuItemConfig(
            title: 'Finance Overview',
            icon: Icons.account_balance_wallet_outlined,
            route: AppRoutes.financeDashboard,
          ),
          MenuItemConfig(
            title: 'Communication Access',
            icon: Icons.forum_outlined,
            route: AppRoutes.communication,
          ),
        ];
      case RoleMapper.analyst:
        return const [
          MenuItemConfig(
            title: 'Analyst Dashboard',
            icon: Icons.dashboard_outlined,
            route: AppRoutes.analystDashboard,
          ),
          MenuItemConfig(
            title: 'Match Analysis',
            icon: Icons.analytics_outlined,
            route: AppRoutes.analysis,
          ),
          MenuItemConfig(
            title: 'Calendar',
            icon: Icons.calendar_month_outlined,
            route: AppRoutes.calendar,
          ),
          MenuItemConfig(
            title: 'Players',
            icon: Icons.people_outline,
            route: AppRoutes.players,
          ),
          MenuItemConfig(
            title: 'Performance Reports',
            icon: Icons.bar_chart_outlined,
            route: AppRoutes.reports,
          ),
          MenuItemConfig(
            title: 'Team Chemistry',
            icon: Icons.hub_outlined,
            route: AppRoutes.chemistry,
          ),
          MenuItemConfig(
            title: 'Tests & Test Types',
            icon: Icons.monitor_heart_outlined,
            route: AppRoutes.tests,
          ),
          MenuItemConfig(
            title: 'Exercises Library',
            icon: Icons.menu_book_outlined,
            route: AppRoutes.exercises,
          ),
        ];
      case RoleMapper.staffTechnique:
        return const [
          MenuItemConfig(
            title: 'Dashboard',
            icon: Icons.speed_outlined,
            route: AppRoutes.coachDashboard,
          ),
          MenuItemConfig(
            title: 'Match Analysis',
            icon: Icons.analytics_outlined,
            route: AppRoutes.analysis,
          ),
          MenuItemConfig(
            title: 'Calendar',
            icon: Icons.calendar_month_outlined,
            route: AppRoutes.calendar,
          ),
          MenuItemConfig(
            title: 'Players',
            icon: Icons.people_outline,
            route: AppRoutes.players,
          ),
          MenuItemConfig(
            title: 'Performance Reports',
            icon: Icons.bar_chart_outlined,
            route: AppRoutes.reports,
          ),
          MenuItemConfig(
            title: 'Team Chemistry',
            icon: Icons.hub_outlined,
            route: AppRoutes.chemistry,
          ),
          MenuItemConfig(
            title: 'Tests & Test Types',
            icon: Icons.monitor_heart_outlined,
            route: AppRoutes.tests,
          ),
          MenuItemConfig(
            title: 'Exercises Library',
            icon: Icons.menu_book_outlined,
            route: AppRoutes.exercises,
          ),
        ];
      case RoleMapper.staffMedical:
        return const [
          MenuItemConfig(
            title: 'Medical Dashboard',
            icon: Icons.health_and_safety_outlined,
            route: AppRoutes.medicalDashboard,
          ),
          MenuItemConfig(
            title: 'Medical Players List',
            icon: Icons.groups_outlined,
            route: AppRoutes.medicalPlayers,
          ),
          MenuItemConfig(
            title: 'Medical Analysis Detail',
            icon: Icons.monitor_heart_outlined,
            route: AppRoutes.medicalAnalysisDetail,
          ),
          MenuItemConfig(
            title: 'Injury Simulation',
            icon: Icons.sports_soccer_outlined,
            route: AppRoutes.medicalSimulation,
          ),
          MenuItemConfig(
            title: 'Recovery Calendar',
            icon: Icons.calendar_month_outlined,
            route: AppRoutes.medicalRecoveryCalendar,
          ),
          MenuItemConfig(
            title: 'Match History',
            icon: Icons.history_rounded,
            route: AppRoutes.medicalMatchHistory,
          ),
        ];
      case RoleMapper.finance:
        return const [
          MenuItemConfig(
            title: 'Finance',
            icon: Icons.account_balance_wallet_outlined,
            route: AppRoutes.financeDashboard,
          ),
          MenuItemConfig(
            title: 'AI Finance',
            icon: Icons.psychology_outlined,
            route: AppRoutes.financeAi,
          ),
          MenuItemConfig(
            title: 'Player Value AI',
            icon: Icons.trending_up_outlined,
            route: AppRoutes.financePlayerValue,
          ),
          MenuItemConfig(
            title: 'Payroll',
            icon: Icons.payments_outlined,
            route: AppRoutes.financePayroll,
          ),
          MenuItemConfig(
            title: 'Budget',
            icon: Icons.account_balance_outlined,
            route: AppRoutes.financeBudget,
          ),
          MenuItemConfig(
            title: 'Sponsors',
            icon: Icons.handshake_outlined,
            route: AppRoutes.financeSponsors,
          ),
          MenuItemConfig(
            title: 'Transfers',
            icon: Icons.swap_horiz_outlined,
            route: AppRoutes.financeTransfers,
          ),
          MenuItemConfig(
            title: 'Treasury',
            icon: Icons.savings_outlined,
            route: AppRoutes.financeTreasury,
          ),
          MenuItemConfig(
            title: 'Audit',
            icon: Icons.verified_user_outlined,
            route: AppRoutes.financeAudit,
          ),
        ];
      case RoleMapper.scout:
        return const [
          MenuItemConfig(
            title: 'Dashboard',
            icon: Icons.radar_outlined,
            route: AppRoutes.scoutDashboard,
          ),
          MenuItemConfig(
            title: 'Players',
            icon: Icons.people_outline,
            route: AppRoutes.players,
          ),
          MenuItemConfig(
            title: 'AI Campaigns',
            icon: Icons.psychology_outlined,
            route: AppRoutes.aiCampaigns,
          ),
          MenuItemConfig(
            title: 'Communication',
            icon: Icons.forum_outlined,
            route: AppRoutes.communication,
          ),
        ];
      case RoleMapper.player:
      default:
        return const [
          MenuItemConfig(
            title: 'Dashboard',
            icon: Icons.sports_soccer_outlined,
            route: AppRoutes.playerDashboard,
          ),
          MenuItemConfig(
            title: 'Calendar',
            icon: Icons.calendar_month_outlined,
            route: AppRoutes.calendar,
          ),
          MenuItemConfig(
            title: 'Communication',
            icon: Icons.forum_outlined,
            route: AppRoutes.communication,
          ),
        ];
    }
  }
}
