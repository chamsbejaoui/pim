import 'package:flutter/material.dart';

import '../../finance/finance.dart';
import '../api/user_management_api.dart';
import '../models/user_management_models.dart';
import 'login_mobile_page.dart';
import 'register_mobile_page.dart';
import 'responsable_approval_mobile_page.dart';

class MobileUserApp extends StatefulWidget {
  const MobileUserApp({super.key});

  @override
  State<MobileUserApp> createState() => _MobileUserAppState();
}

enum _AuthView { login, register }

class _MobileUserAppState extends State<MobileUserApp> {
  final _api = UserManagementApi();
  SessionModel? _session;
  _AuthView _authView = _AuthView.login;

  void _openLogin() {
    setState(() => _authView = _AuthView.login);
  }

  void _openRegister() {
    setState(() => _authView = _AuthView.register);
  }

  void _logout() {
    setState(() {
      _session = null;
      _authView = _AuthView.login;
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = _session;
    if (session == null) {
      if (_authView == _AuthView.register) {
        return RegisterMobilePage(api: _api, onShowLogin: _openLogin);
      }

      return LoginMobilePage(
        api: _api,
        onSession: (newSession) => setState(() => _session = newSession),
        onShowRegister: _openRegister,
      );
    }

    return _buildRoleInterface(session);
  }

  Widget _buildRoleInterface(SessionModel session) {
    final role = session.role;

    if (role == 'CLUB_RESPONSABLE') {
      return ResponsableApprovalMobilePage(
        api: _api,
        session: session,
        onLogout: _logout,
        onOpenMessages: () {},
      );
    }

    if (role == 'FINANCIER') {
      return FinanceMobileShell(
        onLogout: _logout,
        avatarLabel: _avatarLabel(session.email),
        roleLabel: role,
        profileImage: session.photoUrl,
      );
    }

    if (role == 'JOUEUR') {
      return _RoleLandingPage(
        title: 'Espace Joueur',
        subtitle: 'Bienvenue ${session.email}',
        message: 'Votre tableau de bord joueur est actif.',
        icon: Icons.sports_soccer_rounded,
        onLogout: _logout,
      );
    }

    if (role == 'STAFF_TECHNIQUE') {
      return _RoleLandingPage(
        title: 'Espace Staff Technique',
        subtitle: 'Bienvenue ${session.email}',
        message: 'Modules techniques et planning d\'entrainement disponibles.',
        icon: Icons.co_present_rounded,
        onLogout: _logout,
      );
    }

    if (role == 'STAFF_MEDICAL') {
      return _RoleLandingPage(
        title: 'Espace Staff Medical',
        subtitle: 'Bienvenue ${session.email}',
        message: 'Suivi medical et dossiers de soins disponibles.',
        icon: Icons.medical_services_rounded,
        onLogout: _logout,
      );
    }

    if (role == 'ADMIN') {
      return _RoleLandingPage(
        title: 'Admin Web Only',
        subtitle: session.email,
        message: 'Le role ADMIN est reserve a l\'interface web.',
        icon: Icons.desktop_windows_rounded,
        onLogout: _logout,
      );
    }

    return _RoleLandingPage(
      title: 'Role non pris en charge',
      subtitle: session.email,
      message: 'Role recu: $role',
      icon: Icons.warning_amber_rounded,
      onLogout: _logout,
    );
  }

  String _avatarLabel(String email) {
    if (email.isEmpty) {
      return 'U';
    }
    return email[0].toUpperCase();
  }
}

class _RoleLandingPage extends StatelessWidget {
  const _RoleLandingPage({
    required this.title,
    required this.subtitle,
    required this.message,
    required this.icon,
    required this.onLogout,
  });

  final String title;
  final String subtitle;
  final String message;
  final IconData icon;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fg = dark ? Colors.white : const Color(0xFF0B1F3B);
    final muted = dark ? const Color(0xFFAEC3F3) : const Color(0xFF6A769A);
    final panel = dark ? const Color(0x221A3E97) : Colors.white;
    final border = dark ? const Color(0x446893DF) : const Color(0xFFCAD5EC);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: dark
                ? const [
                    Color(0xFF173A97),
                    Color(0xFF0D1F70),
                    Color(0xFF061754),
                  ]
                : const [
                    Color(0xFFF9FBFF),
                    Color(0xFFF1F6FF),
                    Color(0xFFEAF3FF),
                  ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          color: fg,
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: onLogout,
                      icon: Icon(Icons.logout, color: fg),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(subtitle, style: TextStyle(color: muted)),
                const SizedBox(height: 28),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: panel,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: border),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        icon,
                        size: 64,
                        color: dark
                            ? const Color(0xFF5A8FFF)
                            : const Color(0xFF1D7BEA),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: dark
                              ? const Color(0xFFD4E1FF)
                              : const Color(0xFF4F5E86),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
