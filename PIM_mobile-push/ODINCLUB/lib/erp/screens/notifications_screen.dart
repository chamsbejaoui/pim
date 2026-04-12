import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../providers/notifications_provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    Provider.of<NotificationsProvider>(context, listen: false)
        .fetchNotifications();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<NotificationsProvider>(context);

    return Scaffold(
      backgroundColor: OdinTheme.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (provider.unreadCount > 0)
            TextButton.icon(
              onPressed: () => provider.markAllAsRead(),
              icon: const Icon(Icons.done_all_rounded,
                  size: 18, color: OdinTheme.primaryBlue),
              label: const Text(
                'Tout lire',
                style: TextStyle(
                    color: OdinTheme.primaryBlue, fontSize: 12),
              ),
            ),
        ],
      ),
      body: provider.isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(color: OdinTheme.primaryBlue))
          : provider.notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.notifications_off_outlined,
                          size: 64, color: OdinTheme.textTertiary),
                      const SizedBox(height: 16),
                      const Text('Aucune notification',
                          style:
                              TextStyle(color: OdinTheme.textTertiary)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: OdinTheme.primaryBlue,
                  backgroundColor: OdinTheme.surface,
                  onRefresh: () => provider.fetchNotifications(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: provider.notifications.length,
                    itemBuilder: (_, i) =>
                        _buildNotifCard(provider, provider.notifications[i]),
                  ),
                ),
    );
  }

  Widget _buildNotifCard(NotificationsProvider provider, dynamic notif) {
    final typeIcons = {
      'event_reminder': Icons.alarm_rounded,
      'new_event': Icons.event_rounded,
      'event_cancelled': Icons.event_busy_rounded,
      'event_updated': Icons.update_rounded,
      'status_change': Icons.swap_horiz_rounded,
      'participation_request': Icons.person_add_rounded,
      'general': Icons.info_outline_rounded,
    };
    final typeColors = {
      'event_reminder': OdinTheme.accentOrange,
      'new_event': OdinTheme.accentGreen,
      'event_cancelled': OdinTheme.accentRed,
      'event_updated': OdinTheme.accentCyan,
      'status_change': OdinTheme.accentPurple,
      'participation_request': OdinTheme.primaryBlue,
      'general': OdinTheme.textSecondary,
    };

    final icon = typeIcons[notif.notificationType] ?? Icons.notifications_rounded;
    final color = typeColors[notif.notificationType] ?? OdinTheme.primaryBlue;

    return Dismissible(
      key: Key(notif.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: OdinTheme.accentRed.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_rounded, color: OdinTheme.accentRed),
      ),
      onDismissed: (_) => provider.deleteNotification(notif.id),
      child: GestureDetector(
        onTap: () {
          if (!notif.isRead) {
            provider.markAsRead(notif.id);
          }
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: notif.isRead ? OdinTheme.cardGradient : null,
            color: notif.isRead ? null : OdinTheme.primaryBlue.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: notif.isRead
                  ? OdinTheme.cardBorder
                  : OdinTheme.primaryBlue.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notif.title,
                            style: TextStyle(
                              color: OdinTheme.textPrimary,
                              fontWeight: notif.isRead
                                  ? FontWeight.w500
                                  : FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        if (!notif.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: OdinTheme.primaryBlue,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notif.message,
                      style: const TextStyle(
                        color: OdinTheme.textSecondary,
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            notif.typeLabel,
                            style: TextStyle(
                              color: color,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (notif.createdAt != null)
                          Text(
                            _timeAgo(notif.createdAt!),
                            style: const TextStyle(
                              color: OdinTheme.textTertiary,
                              fontSize: 10,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}j';
    return DateFormat('dd/MM').format(dt);
  }
}
