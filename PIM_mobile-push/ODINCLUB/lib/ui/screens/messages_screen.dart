import 'package:flutter/material.dart';
import '../components/empty_state.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      title: 'No messages yet',
      message: 'Your team conversations will appear here.',
      icon: Icons.chat_bubble_outline_rounded,
    );
  }
}
