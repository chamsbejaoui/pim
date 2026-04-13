import 'package:flutter/material.dart';
import '../../screens/admin_dashboard_screen.dart';
import '../../screens/responsable_approval_screen.dart';
import '../../screens/analysis/analysis_shell_screen.dart';
import '../../screens/analysis/upload_video_screen.dart';
import '../../screens/profile_screen.dart';
import '../../screens/roles/club_responsable_dashboard_screen.dart';
import '../../screens/roles/analyst_dashboard_screen.dart';
import '../../screens/roles/joueur_dashboard_screen.dart';
import '../../screens/roles/staff_technique_dashboard_screen.dart';
import '../../screens/roles/staff_medical_dashboard_screen.dart';
import '../../screens/roles/finance_dashboard_screen.dart';
import '../../screens/roles/scout_dashboard_screen.dart';
import '../../screens/medical/medical_analysis_detail_screen.dart';
import '../../screens/medical/medical_players_screen.dart';
import '../../screens/medical/medical_recovery_calendar_screen.dart';
import '../../screens/medical/simulation_history_screen.dart';
import '../../screens/medical/simulation_screen.dart';
import '../../sports_performance/screens/calendar/calendar_screen.dart';
import '../../sports_performance/screens/players/players_list_screen.dart';
import '../../sports_performance/screens/reports/all_events_reports_screen.dart';
import '../../sports_performance/screens/test_types/test_types_list_screen.dart';
import '../../sports_performance/screens/exercises/library_screen.dart';
import '../../sports_performance/cognitive_lab/screens/cognitive_dashboard_screen.dart';
import '../../sports_performance/cognitive_lab/screens/squad_cognitive_overview_screen.dart';
import '../../screens/ai/ai_campaign_screen.dart';
import '../../user_management/models/user_management_models.dart';
import '../screens/admin_users_screen.dart';
import '../screens/audit_log_screen.dart';
import '../screens/communication_shell_screen.dart';
import '../screens/communication_notifications_shell_screen.dart';
import '../../season_planning/screens/season_list_screen.dart';
import '../../tactics/screens/tactics_board_screen.dart';
import '../../screens/chemistry/team_chemistry_screen.dart';

class AppRouteData {
  const AppRouteData({
    required this.title,
    required this.builder,
    this.showAppBar = true,
    this.usePadding = true,
  });

  final String title;
  final WidgetBuilder builder;
  final bool showAppBar;
  final bool usePadding;
}

class AppRoutes {
  AppRoutes._();

  static const String adminDashboard = '/admin/dashboard';
  static const String adminUsers = '/admin/users';
  static const String auditLog = '/admin/audit-log';
  static const String analystDashboard = '/analyst/dashboard';
  static const String clubDashboard = '/club/dashboard';
  static const String coachDashboard = '/coach/dashboard';
  static const String medicalDashboard = '/medical/dashboard';
  static const String financeDashboard = '/finance/dashboard';
  static const String playerDashboard = '/player/dashboard';
  static const String scoutDashboard = '/scout/dashboard';

  static const String seasonPlanning = '/season-planning';
  static const String tactics = '/tactics';
  static const String chemistry = '/chemistry';

  static const String approvals = '/club/approvals';
  static const String analysis = '/analysis';
  static const String uploadVideo = '/analysis/upload';
  static const String medicalPlayers = '/medical/players';
  static const String medicalAnalysisDetail = '/medical/analysis';
  static const String medicalSimulation = '/medical/simulation';
  static const String medicalRecoveryCalendar = '/medical/recovery-calendar';
  static const String medicalMatchHistory = '/medical/match-history';
  static const String players = '/players';
  static const String calendar = '/calendar';
  static const String reports = '/reports';
  static const String tests = '/tests';
  static const String exercises = '/exercises';
  static const String financeWorkspace = '/finance/workspace';
  static const String financePayroll = '/finance/payroll';
  static const String financeBudget = '/finance/budget';
  static const String financeSponsors = '/finance/sponsors';
  static const String financeTransfers = '/finance/transfers';
  static const String financeTreasury = '/finance/treasury';
  static const String financeAudit = '/finance/audit';
  static const String financeAi = '/finance/ai';
  static const String financePlayerValue = '/finance/player-value';
  static const String aiCampaigns = '/ai/campaigns';
  static const String cognitiveDashboard = '/cognitive/dashboard';
  static const String squadCognitiveOverview = '/cognitive/squad-overview';
  static const String communication = '/communication';

  static const String messages = '/messages';
  static const String notifications = '/notifications';
  static const String profile = '/profile';

  static AppRouteData resolve(String route, SessionModel session) {
    switch (route) {
      case adminDashboard:
        return AppRouteData(
          title: 'Admin Dashboard',
          builder: (_) => const AdminDashboardScreen(),
          showAppBar: false,
          usePadding: false,
        );
      case adminUsers:
        return AppRouteData(
          title: 'User management',
          builder: (_) => const AdminUsersScreen(),
        );
      case auditLog:
        return AppRouteData(
          title: 'Audit log',
          builder: (_) => const AuditLogScreen(),
        );
      case analystDashboard:
        return AppRouteData(
          title: 'Analyst Dashboard',
          builder: (_) => AnalystDashboardScreen(session: session),
        );
      case clubDashboard:
        return AppRouteData(
          title: 'Club Dashboard',
          builder: (_) => ClubResponsableDashboardScreen(session: session),
        );
      case coachDashboard:
        return AppRouteData(
          title: 'Coach Dashboard',
          builder: (_) => StaffTechniqueDashboardScreen(session: session),
        );
      case medicalDashboard:
        return AppRouteData(
          title: 'Medical Dashboard',
          builder: (_) => StaffMedicalDashboardScreen(session: session),
        );
      case financeDashboard:
        return AppRouteData(
          title: 'Finance Dashboard',
          builder: (_) => FinanceDashboardScreen(session: session),
          showAppBar: true,
          usePadding: false,
        );
      case financePayroll:
        return AppRouteData(
          title: 'Payroll',
          builder: (_) =>
              FinanceDashboardScreen(session: session, initialIndex: 3),
          showAppBar: true,
          usePadding: false,
        );
      case financeBudget:
        return AppRouteData(
          title: 'Budget',
          builder: (_) =>
              FinanceDashboardScreen(session: session, initialIndex: 6),
          showAppBar: true,
          usePadding: false,
        );
      case financeSponsors:
        return AppRouteData(
          title: 'Sponsors',
          builder: (_) =>
              FinanceDashboardScreen(session: session, initialIndex: 1),
          showAppBar: true,
          usePadding: false,
        );
      case financeTransfers:
        return AppRouteData(
          title: 'Transfers',
          builder: (_) =>
              FinanceDashboardScreen(session: session, initialIndex: 4),
          showAppBar: true,
          usePadding: false,
        );
      case financeTreasury:
        return AppRouteData(
          title: 'Treasury',
          builder: (_) =>
              FinanceDashboardScreen(session: session, initialIndex: 5),
          showAppBar: true,
          usePadding: false,
        );
      case financeAudit:
        return AppRouteData(
          title: 'Audit',
          builder: (_) =>
              FinanceDashboardScreen(session: session, initialIndex: 7),
          showAppBar: true,
          usePadding: false,
        );
      case financeAi:
        return AppRouteData(
          title: 'AI Finance',
          builder: (_) =>
              FinanceDashboardScreen(session: session, initialIndex: 8),
          showAppBar: true,
          usePadding: false,
        );
      case financePlayerValue:
        return AppRouteData(
          title: 'Player Value AI',
          builder: (_) =>
              FinanceDashboardScreen(session: session, initialIndex: 9),
          showAppBar: true,
          usePadding: false,
        );
      case playerDashboard:
        return AppRouteData(
          title: 'Espace Joueur',
          builder: (_) => JoueurDashboardScreen(session: session),
        );
      case scoutDashboard:
        return AppRouteData(
          title: 'Scout',
          builder: (_) => ScoutDashboardScreen(session: session),
        );
      case approvals:
        return AppRouteData(
          title: 'Approvals',
          builder: (_) => ResponsableApprovalScreen(session: session),
          showAppBar: true,
          usePadding: false,
        );
      case analysis:
        return AppRouteData(
          title: 'Match Analysis',
          builder: (_) => AnalysisShellScreen(session: session),
          showAppBar: true,
          usePadding: false,
        );
      case uploadVideo:
        return AppRouteData(
          title: 'Upload Video',
          builder: (_) => const UploadVideoScreen(),
        );
      case medicalPlayers:
        return AppRouteData(
          title: 'Medical Players',
          builder: (_) => const MedicalPlayersScreen(),
        );
      case medicalAnalysisDetail:
        return AppRouteData(
          title: 'Medical Analysis Detail',
          builder: (_) => const MedicalAnalysisDetailScreen(),
        );
      case medicalSimulation:
        return AppRouteData(
          title: 'Injury Simulation',
          builder: (_) => const SimulationScreen(),
          showAppBar: true,
          usePadding: false,
        );
      case medicalRecoveryCalendar:
        return AppRouteData(
          title: 'Recovery Calendar',
          builder: (_) => const MedicalRecoveryCalendarScreen(),
        );
      case medicalMatchHistory:
        return AppRouteData(
          title: 'Match History',
          builder: (_) => const SimulationHistoryScreen(),
        );
      case players:
        return AppRouteData(
          title: 'Players',
          builder: (_) => const PlayersListScreen(),
          showAppBar: true,
          usePadding: false,
        );
      case calendar:
        return AppRouteData(
          title: 'Calendar',
          builder: (_) => const CalendarScreen(),
          showAppBar: true,
          usePadding: false,
        );
      case reports:
        return AppRouteData(
          title: 'Performance Reports',
          builder: (_) => const AllEventsReportsScreen(),
          showAppBar: true,
          usePadding: false,
        );
      case tests:
        return AppRouteData(
          title: 'Tests & Test Types',
          builder: (_) => const TestTypesListScreen(),
          showAppBar: true,
          usePadding: false,
        );
      case exercises:
        return AppRouteData(
          title: 'Exercises Library',
          builder: (_) => const LibraryScreen(),
          showAppBar: true,
          usePadding: false,
        );
      case aiCampaigns:
        return AppRouteData(
          title: 'AI Campaigns',
          builder: (_) => const AiCampaignScreen(),
          showAppBar: false,
          usePadding: false,
        );
      case cognitiveDashboard:
        return AppRouteData(
          title: 'Labo Cognitif IA',
          builder: (_) => CognitiveDashboardScreen(session: session),
          showAppBar: false,
          usePadding: false,
        );
      case squadCognitiveOverview:
        return AppRouteData(
          title: 'Vue Equipe Cognitive',
          builder: (_) => const SquadCognitiveOverviewScreen(),
          showAppBar: false,
          usePadding: false,
        );
      case communication:
        return AppRouteData(
          title: 'Communication',
          builder: (_) => CommunicationShellScreen(session: session),
          showAppBar: true,
          usePadding: false,
        );
      case messages:
        return AppRouteData(
          title: 'Messages',
          builder: (_) => CommunicationShellScreen(session: session),
          showAppBar: true,
          usePadding: false,
        );
      case notifications:
        return AppRouteData(
          title: 'Notifications',
          builder: (_) =>
              CommunicationNotificationsShellScreen(session: session),
          showAppBar: true,
          usePadding: false,
        );
      case profile:
        return AppRouteData(
          title: 'Profile',
          builder: (_) => const ProfileScreen(),
        );
      case seasonPlanning:
        return AppRouteData(
          title: 'Planification de Saison',
          builder: (_) => const SeasonListScreen(),
          showAppBar: false,
          usePadding: false,
        );
      case tactics:
        return AppRouteData(
          title: 'IA Tactique',
          builder: (_) => const TacticsBoardScreen(),
          showAppBar: false,
          usePadding: false,
        );
      case chemistry:
        return AppRouteData(
          title: 'Team Chemistry',
          builder: (_) => const TeamChemistryScreen(),
          showAppBar: true,
          usePadding: true,
        );
      default:
        return AppRouteData(
          title: 'Dashboard',
          builder: (_) => const Center(child: Text('Route not found')),
        );
    }
  }
}


