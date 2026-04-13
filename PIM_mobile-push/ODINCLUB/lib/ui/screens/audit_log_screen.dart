import 'package:flutter/material.dart';
import '../components/empty_state.dart';

class AuditLogScreen extends StatelessWidget {
  const AuditLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      title: 'Audit log',
      message: 'Aucune entree d\'audit pour le moment.',
      icon: Icons.receipt_long_outlined,
    );
  }
}
