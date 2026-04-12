import 'package:flutter/material.dart';
import 'package:odinclub/user_management/api/user_management_api.dart';
import 'package:odinclub/user_management/models/user_management_models.dart';

import 'screens/admin_dashboard_screen.dart';
import 'screens/admin_login_screen.dart';
import 'widgets/admin_shell_frame.dart';

class AdminWebShell extends StatefulWidget {
  const AdminWebShell({super.key, required this.onToggleTheme});

  final VoidCallback onToggleTheme;

  @override
  State<AdminWebShell> createState() => _AdminWebShellState();
}

class _AdminWebShellState extends State<AdminWebShell> {
  final _api = UserManagementApi();
  SessionModel? _session;
  String? _error;

  Future<String?> _onLogin(String email, String password) async {
    try {
      final session = await _api.login(email, password);
      if (session.role != 'ADMIN') {
        return 'Access denied: ADMIN only';
      }

      setState(() {
        _session = session;
        _error = null;
      });
      return null;
    } catch (error) {
      final message = error.toString().replaceFirst('Exception: ', '');
      setState(() => _error = message);
      return message;
    }
  }

  void _onLogout() {
    setState(() => _session = null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AdminShellFrame(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 320),
          child: _session == null
              ? AdminLoginScreen(
                  key: const ValueKey('login'),
                  onLogin: _onLogin,
                  errorText: _error,
                )
              : AdminDashboardScreen(
                  key: const ValueKey('dashboard'),
                  adminName: _session!.email,
                  token: _session!.token,
                  onLogout: _onLogout,
                  onToggleTheme: widget.onToggleTheme,
                  api: _api,
                ),
        ),
      ),
    );
  }
}
