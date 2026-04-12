import 'package:flutter/material.dart';
import '../components/empty_state.dart';

class AdminUsersScreen extends StatelessWidget {
  const AdminUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      title: 'User management',
      message: 'User management is not available on mobile yet.',
      icon: Icons.manage_accounts_outlined,
    );
  }
}
