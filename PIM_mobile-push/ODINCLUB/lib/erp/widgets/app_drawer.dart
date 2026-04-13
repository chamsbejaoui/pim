import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;

    return Drawer(
      backgroundColor: OdinTheme.surface,
      child: Column(
        children: [
          // ─── Header ──────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 24),
            decoration: const BoxDecoration(
              gradient: OdinTheme.primaryGradient,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      user != null
                          ? '${user.firstName.isNotEmpty ? user.firstName[0] : ''}${user.lastName.isNotEmpty ? user.lastName[0] : ''}'
                          : 'OE',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  user?.fullName ?? 'Odin ERP',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.role ?? '',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          // ─── Nav items ───────────────────────────────────────
          const SizedBox(height: 8),
          _buildNavItem(
            context,
            icon: Icons.dashboard_rounded,
            label: 'Dashboard',
            route: '/dashboard',
          ),
          if (user?.role != 'player') ...[
            _buildNavItem(
              context,
              icon: Icons.people_rounded,
              label: 'Joueurs',
              route: '/players',
            ),
            _buildNavItem(
              context,
              icon: Icons.badge_rounded,
              label: 'Staff',
              route: '/staff',
            ),
          ] else ...[
            _buildNavItem(
              context,
              icon: Icons.person_rounded,
              label: 'Mon Profil',
              route: '/players/detail',
            ),
          ],
          _buildNavItem(
            context,
            icon: Icons.calendar_month_rounded,
            label: 'Événements',
            route: '/events',
          ),
          _buildNavItem(
            context,
            icon: Icons.notifications_rounded,
            label: 'Notifications',
            route: '/notifications',
          ),

          if (user?.role != 'player') ...[
            const Divider(color: OdinTheme.cardBorder, height: 32),

            _buildNavItem(
              context,
              icon: Icons.groups_rounded,
              label: 'Équipes',
              route: '/teams',
            ),
            _buildNavItem(
              context,
              icon: Icons.category_rounded,
              label: 'Catégories',
              route: '/categories',
            ),
          ],

          const Spacer(),

          // ─── Logout ──────────────────────────────────────────
          Container(
            margin: const EdgeInsets.all(16),
            child: ListTile(
              leading: const Icon(Icons.logout_rounded,
                  color: OdinTheme.accentRed),
              title: const Text(
                'Déconnexion',
                style: TextStyle(color: OdinTheme.accentRed),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                    color: OdinTheme.accentRed.withValues(alpha: 0.3)),
              ),
              onTap: () {
                Navigator.of(context).pop(); // close drawer
                auth.logout();
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String route,
  }) {
    final currentRoute = ModalRoute.of(context)?.settings.name;
    final isActive = currentRoute == route;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: isActive
            ? OdinTheme.primaryBlue.withValues(alpha: 0.15)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isActive ? OdinTheme.primaryBlue : OdinTheme.textTertiary,
          size: 22,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: isActive ? OdinTheme.primaryBlue : OdinTheme.textSecondary,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            fontSize: 14,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        onTap: () {
          Navigator.of(context).pop(); // close drawer
          if (currentRoute != route) {
            Navigator.of(context).pushReplacementNamed(route);
          }
        },
      ),
    );
  }
}
