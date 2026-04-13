import 'package:flutter/material.dart';
import '../components/empty_state.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      title: 'No notifications',
      message: 'Alerts and approvals will show up here.',
      icon: Icons.notifications_none_rounded,
    );
  }
}
