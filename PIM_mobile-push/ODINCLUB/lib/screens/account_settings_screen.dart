import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/theme_controller.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = ThemeController.isDark(context);
    return Scaffold(
      backgroundColor: AppTheme.lightGrey,
      appBar: AppBar(
        backgroundColor: AppTheme.white,
        foregroundColor: AppTheme.blueFonce,
        elevation: 0,
        title: const Text(
          'Account & Settings',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _sectionTitle('Appearance'),
          _tile(
            icon: isDark ? Icons.dark_mode : Icons.light_mode,
            title: 'Dark mode',
            subtitle: isDark ? 'On' : 'Off',
            trailing: Switch(
              value: isDark,
              onChanged: (_) => ThemeController.toggle(),
              activeColor: AppTheme.blueCiel,
            ),
          ),
          const Divider(height: 1),
          _sectionTitle('Account'),
          _tile(
            icon: Icons.person_outline,
            title: 'Profile',
            subtitle: 'Name, email, role',
            onTap: () {},
          ),
          _tile(
            icon: Icons.lock_outline,
            title: 'Password',
            subtitle: 'Change password',
            onTap: () {},
          ),
          _tile(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            subtitle: 'Manage notifications',
            onTap: () {},
          ),
          const Divider(height: 1),
          _sectionTitle('About'),
          _tile(
            icon: Icons.info_outline,
            title: 'Version',
            subtitle: '1.0.0',
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppTheme.darkGrey.withOpacity(0.8),
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _tile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppTheme.blueCiel.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppTheme.blueFonce, size: 22),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: AppTheme.blueFonce,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 13,
          color: AppTheme.darkGrey.withOpacity(0.7),
        ),
      ),
      trailing: trailing,
      onTap: onTap,
    );
  }
}
