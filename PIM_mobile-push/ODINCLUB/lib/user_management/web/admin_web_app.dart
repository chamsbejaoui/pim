import 'package:flutter/material.dart';

import '../api/user_management_api.dart';
import '../models/user_management_models.dart';
import 'admin_login_web_page.dart';
import 'admin_pending_clubs_web_page.dart';

class AdminWebApp extends StatefulWidget {
  const AdminWebApp({super.key});

  @override
  State<AdminWebApp> createState() => _AdminWebAppState();
}

class _AdminWebAppState extends State<AdminWebApp> {
  final _api = UserManagementApi();
  SessionModel? _session;
  String? _error;

  Future<void> _handleLogin(String email, String password) async {
    try {
      final session = await _api.login(email, password);
      if (session.role != 'ADMIN') {
        throw Exception('Acces reserve aux admins web.');
      }
      setState(() {
        _session = session;
        _error = null;
      });
    } catch (error) {
      setState(() => _error = error.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _logout() {
    setState(() => _session = null);
  }

  @override
  Widget build(BuildContext context) {
    if (_session == null) {
      return AdminLoginWebPage(onLogin: _handleLogin, errorText: _error);
    }

    return AdminPendingClubsWebPage(
      token: _session!.token,
      onLogout: _logout,
      api: _api,
    );
  }
}
