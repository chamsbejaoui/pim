import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../user_management/api/user_management_api.dart';
import '../user_management/models/user_management_models.dart';
import '../user_management/mobile/responsable_approval_mobile_page.dart';
import '../finance/theme/finance_theme.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class ResponsableApprovalScreen extends StatelessWidget {
  ResponsableApprovalScreen({
    super.key,
    required this.session,
    UserManagementApi? api,
  }) : _api = api ?? UserManagementApi();

  final SessionModel session;
  final UserManagementApi _api;

  Future<void> _logout(BuildContext context) async {
    final apiService = ApiService();
    await apiService.removeToken();
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  void _openMessages(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: buildFinanceDarkTheme(),
      child: ResponsableApprovalMobilePage(
        api: _api,
        session: session,
        onLogout: () => _logout(context),
        onOpenMessages: () => _openMessages(context),
      ),
    );
  }
}
