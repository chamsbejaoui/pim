import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';

import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/players/players_list_screen.dart';
import '../screens/players/player_detail_screen.dart';
import '../screens/players/player_form_screen.dart';
import '../screens/staff/staff_list_screen.dart';
import '../screens/staff/staff_detail_screen.dart';
import '../screens/staff/staff_form_screen.dart';
import '../screens/events/events_screen.dart';
import '../screens/events/event_detail_screen.dart';
import '../screens/events/event_form_screen.dart';
import '../screens/scouting/scouting_screen.dart';
import '../screens/medical/medical_vault_screen.dart';
import '../screens/finance/finance_dashboard_screen.dart';
import '../screens/notifications_screen.dart';
import '../screens/role_based_layout.dart';
import '../screens/admin/pending_users_screen.dart';
import '../screens/readiness/readiness_screen.dart';

class AppRouter {
  static GoRouter createRouter(AuthProvider authProvider) {
    return GoRouter(
      initialLocation: '/login',
      refreshListenable: authProvider,
      redirect: (context, state) {
        final isLoggedIn = authProvider.isAuthenticated;
        final isAuthRoute = state.matchedLocation == '/login' ||
            state.matchedLocation == '/register';

        if (!isLoggedIn) {
          // If unauthenticated and not already on login/register, force to login.
          return isAuthRoute ? null : '/login';
        }

        if (isAuthRoute || state.matchedLocation == '/') {
          final role = authProvider.user?.role ?? 'player';
          switch (role) {
            case 'admin':
            case 'responsable':
              return '/admin/hub';
            case 'coach':
            case 'entraineur':
              return '/coach/hub';
            case 'medical':
            case 'medical_staff':
              return '/medical/hub';
            case 'accountant':
            case 'admin_finance':
              return '/finance/hub';
            case 'player':
            case 'joueur':
            default:
              return '/player/hub';
          }
        }

        return null; // Return null to stay on the current route
      },
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterScreen(),
        ),

        // === ADMIN ROUTES ===
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) =>
              RoleBasedLayout(navigationShell: navigationShell),
          branches: [
            StatefulShellBranch(routes: [
              GoRoute(
                  path: '/admin/hub',
                  builder: (context, state) => const DashboardScreen()),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                  path: '/admin/squad',
                  builder: (context, state) => const PlayersListScreen()),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                  path: '/admin/finance',
                  builder: (context, state) => const DashboardScreen()), // Placeholders for now
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                  path: '/admin/tactical',
                  builder: (context, state) => const EventsScreen()),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                  path: '/admin/settings',
                  builder: (context, state) => const StaffListScreen()), // Placeholders for now
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                  path: '/admin/pending-users',
                  builder: (context, state) => const PendingUsersScreen()),
            ]),
          ],
        ),

        // === COACH ROUTES ===
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) =>
              RoleBasedLayout(navigationShell: navigationShell),
          branches: [
            StatefulShellBranch(routes: [
              GoRoute(
                  path: '/coach/hub',
                  builder: (context, state) => const DashboardScreen()),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                  path: '/coach/squad',
                  builder: (context, state) => const PlayersListScreen()),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                  path: '/coach/train',
                  builder: (context, state) => const EventsScreen()),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                  path: '/coach/scout',
                  builder: (context, state) => const ScoutingScreen()),
            ]),
          ],
        ),

        // === MEDICAL ROUTES ===
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) =>
              RoleBasedLayout(navigationShell: navigationShell),
          branches: [
            StatefulShellBranch(routes: [
              GoRoute(
                  path: '/medical/hub',
                  builder: (context, state) => const DashboardScreen()),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                  path: '/medical/vault',
                  builder: (context, state) => const MedicalVaultScreen()),
            ]),
          ],
        ),
        
        // === FINANCE ROUTES ===
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) =>
              RoleBasedLayout(navigationShell: navigationShell),
          branches: [
            StatefulShellBranch(routes: [
              GoRoute(
                  path: '/finance/hub',
                  builder: (context, state) => const FinanceDashboardScreen()),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                  path: '/finance/reports',
                  builder: (context, state) => const DashboardScreen()), // Placeholder
            ]),
          ],
        ),

        // === PLAYER ROUTES ===
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) =>
              RoleBasedLayout(navigationShell: navigationShell),
          branches: [
            StatefulShellBranch(routes: [
              GoRoute(
                  path: '/player/hub',
                  builder: (context, state) => const DashboardScreen()),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                  path: '/player/schedule',
                  builder: (context, state) => const EventsScreen()),
            ]),
          ],
        ),

        // === STANDALONE SUB-ROUTES ===
        GoRoute(
          path: '/players',
          builder: (context, state) => const PlayersListScreen(),
        ),
        GoRoute(
          path: '/staff',
          builder: (context, state) => const StaffListScreen(),
        ),
        GoRoute(
          path: '/events',
          builder: (context, state) => const EventsScreen(),
        ),
        GoRoute(
          path: '/players/detail',
          builder: (context, state) => PlayerDetailScreen(playerId: state.extra as String?),
        ),
        GoRoute(
          path: '/players/form',
          builder: (context, state) => PlayerFormScreen(playerId: state.extra as String?),
        ),
        GoRoute(
          path: '/staff/detail',
          builder: (context, state) => StaffDetailScreen(staffId: state.extra as String?),
        ),
        GoRoute(
          path: '/staff/form',
          builder: (context, state) => StaffFormScreen(staffId: state.extra as String?),
        ),
        GoRoute(
          path: '/events/detail',
          builder: (context, state) => EventDetailScreen(eventId: state.extra as String?),
        ),
        GoRoute(
          path: '/events/form',
          builder: (context, state) => EventFormScreen(eventId: state.extra as String?),
        ),
        GoRoute(
          path: '/notifications',
          builder: (context, state) => const NotificationsScreen(),
        ),
        GoRoute(
          path: '/readiness',
          builder: (context, state) => const ReadinessScreen(),
        ),
      ],
    );
  }
}
