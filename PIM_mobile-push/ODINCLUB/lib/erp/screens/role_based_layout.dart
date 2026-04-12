import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';

class RoleBasedLayout extends StatelessWidget {
  const RoleBasedLayout({
    super.key,
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userRole = authProvider.user?.role ?? 'player';

    // Define tabs dynamically based on role
    List<_NavItem> tabs = _getTabsForRole(userRole);

    return Scaffold(
      backgroundColor: OdinTheme.background,
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: OdinTheme.surface,
          border: const Border(
            top: BorderSide(color: OdinTheme.cardBorder, width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: tabs.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return _buildNavItem(
                  index: index,
                  icon: item.icon,
                  label: item.label,
                  isActive: navigationShell.currentIndex == index,
                  onTap: () => _goBranch(index),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  void _goBranch(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? OdinTheme.primaryBlue.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? OdinTheme.primaryBlue : OdinTheme.textTertiary,
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? OdinTheme.primaryBlue : OdinTheme.textTertiary,
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<_NavItem> _getTabsForRole(String role) {
    switch (role) {
      case 'admin':
      case 'responsable':
        return [
          _NavItem(icon: Icons.dashboard_rounded, label: 'Hub'),
          _NavItem(icon: Icons.people_rounded, label: 'Squad'),
          _NavItem(icon: Icons.account_balance_wallet_rounded, label: 'Finance'),
          _NavItem(icon: Icons.event_note_rounded, label: 'Tactical'),
          _NavItem(icon: Icons.badge_rounded, label: 'Staff'),
        ];
      case 'coach':
      case 'entraineur':
        return [
          _NavItem(icon: Icons.bar_chart_rounded, label: 'Hub'),
          _NavItem(icon: Icons.people_outline_rounded, label: 'Squad'),
          _NavItem(icon: Icons.sports_soccer_rounded, label: 'Train'),
          _NavItem(icon: Icons.radar_rounded, label: 'Scout'),
        ];
      case 'medical':
      case 'medical_staff':
        return [
          _NavItem(icon: Icons.medical_services_rounded, label: 'Hub'),
          _NavItem(icon: Icons.local_hospital_rounded, label: 'Vault'),
        ];
      case 'accountant':
      case 'admin_finance':
        return [
          _NavItem(icon: Icons.account_balance_wallet_rounded, label: 'Finance'),
          _NavItem(icon: Icons.picture_as_pdf_rounded, label: 'Reports'),
        ];
      case 'player':
      case 'joueur':
      default:
        return [
          _NavItem(icon: Icons.person_rounded, label: 'Hub'),
          _NavItem(icon: Icons.calendar_today_rounded, label: 'Schedule'),
        ];
    }
  }
}

class _NavItem {
  final IconData icon;
  final String label;

  _NavItem({required this.icon, required this.label});
}
