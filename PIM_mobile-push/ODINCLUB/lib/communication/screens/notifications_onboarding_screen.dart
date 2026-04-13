import 'package:flutter/material.dart';

import '../communication_theme.dart';

class NotificationsOnboardingScreen extends StatelessWidget {
  const NotificationsOnboardingScreen({
    super.key,
    required this.onSkip,
    required this.onEnable,
    this.embedded = false,
  });

  final VoidCallback onSkip;
  final VoidCallback onEnable;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final card = CommunicationPalette.card(context);
    final fg = CommunicationPalette.textPrimary(context);
    final muted = CommunicationPalette.textMuted(context);

    final body = Container(
      decoration: CommunicationPalette.backgroundDecoration(),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Get notified about important stuff',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 10),
            Text(
              'We will notify you for chat activity, training reminders, medical alerts and emergency messages.',
              style: TextStyle(color: muted, height: 1.45),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: card,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                children: [
                  _LineItem(label: 'Coach announcements'),
                  _LineItem(label: 'Medical alerts'),
                  _LineItem(label: 'Training reminders'),
                  _LineItem(label: 'Emergency notifications'),
                ],
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onSkip,
                    child: const Text('Later'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: onEnable,
                    child: const Text('Get notified'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (embedded) {
      return body;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: body,
    );
  }
}

class _LineItem extends StatelessWidget {
  const _LineItem({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            Icons.notifications_active_outlined,
            size: 18,
            color: CommunicationPalette.secondary,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
        ],
      ),
    );
  }
}
