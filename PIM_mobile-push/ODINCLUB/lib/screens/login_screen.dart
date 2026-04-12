import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../user_management/api/user_management_api.dart';
import '../user_management/models/user_management_models.dart';
import '../user_management/mobile/login_mobile_page.dart';
import 'register_screen.dart';
import '../utils/role_router.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final UserManagementApi _api = UserManagementApi();
  final ApiService _apiService = ApiService();
  bool _navigating = false;

  Future<void> _handleSession(SessionModel session) async {
    if (_navigating) return;
    setState(() => _navigating = true);
    await _apiService.saveToken(session.token);

    if (!mounted) return;

    final target = buildRoleHome(session);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => target),
    );
  }

  void _openRegister() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LoginMobilePage(
      api: _api,
      onSession: _handleSession,
      onShowRegister: _openRegister,
    );
  }
}
