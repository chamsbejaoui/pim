import 'package:flutter/material.dart';
import '../components/empty_state.dart';

class PlayerStatusScreen extends StatelessWidget {
  const PlayerStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      title: 'Physical status',
      message: 'Les donnees de forme et de recuperation apparaitront ici.',
      icon: Icons.monitor_heart_outlined,
    );
  }
}
