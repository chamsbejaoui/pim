import 'package:flutter/material.dart';
import '../../finance/finance_mobile_shell.dart';
import '../../user_management/models/user_management_models.dart';

class FinanceDashboardScreen extends StatelessWidget {
  const FinanceDashboardScreen({
    super.key,
    required this.session,
    this.initialIndex,
  });

  final SessionModel session;
  final int? initialIndex;

  String _avatarLabel(String email) {
    if (email.isEmpty) return 'F';
    return email[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return FinanceMobileShell(
      embedded: true,
      avatarLabel: _avatarLabel(session.email),
      roleLabel: session.role,
      profileImage: session.photoUrl,
      initialIndex: initialIndex,
    );
  }
}
