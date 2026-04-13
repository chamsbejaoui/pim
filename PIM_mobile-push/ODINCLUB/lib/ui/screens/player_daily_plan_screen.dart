import 'package:flutter/material.dart';
import '../components/empty_state.dart';

class PlayerDailyPlanScreen extends StatelessWidget {
  const PlayerDailyPlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      title: 'Daily plan',
      message: 'Votre programme quotidien apparaitra ici.',
      icon: Icons.event_note_outlined,
    );
  }
}
