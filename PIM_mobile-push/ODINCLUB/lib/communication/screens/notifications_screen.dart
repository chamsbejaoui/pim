import 'dart:async';

import 'package:flutter/material.dart';

import '../../user_management/api/user_management_api.dart';
import '../../user_management/models/user_management_models.dart';
import '../../utils/role_mapper.dart';
import '../../ui/navigation/app_routes.dart';
import '../../ui/shell/app_shell.dart';
import '../communication_theme.dart';
import '../models/communication_models.dart';
import 'notifications_onboarding_screen.dart';
import '../../ui/components/app_card.dart';
import '../../ui/components/empty_state.dart';
import '../../ui/theme/app_spacing.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({
    super.key,
    required this.api,
    required this.session,
    required this.onOpenConversation,
    this.embedded = false,
  });

  final UserManagementApi api;
  final SessionModel session;
  final void Function(String conversationId) onOpenConversation;
  final bool embedded;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _onboardingDone = false;
  bool _loading = true;
  String? _error;
  int _pendingApprovals = 0;

  List<NotificationModel> _notifications = [];
  StreamSubscription<Map<String, dynamic>>? _notificationSub;

  @override
  void initState() {
    super.initState();
    _subscribeRealtime();
  }

  @override
  void dispose() {
    _notificationSub?.cancel();
    super.dispose();
  }

  void _subscribeRealtime() {
    _notificationSub?.cancel();
    _notificationSub = widget.api
        .subscribeSse(
          token: widget.session.token,
          path: '/notifications/stream',
        )
        .listen((event) {
          final eventType = (event['eventType'] ?? '').toString();
          if (eventType != 'heartbeat') {
            _loadNotifications();
          }
        });
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final rows = await widget.api.getNotifications(widget.session.token);
      if (RoleMapper.normalize(widget.session.role) ==
          RoleMapper.clubResponsable) {
        try {
          final pending = await widget.api.getPendingUsers(
            widget.session.token,
          );
          _pendingApprovals = pending.length;
        } catch (_) {
          _pendingApprovals = 0;
        }
      } else {
        _pendingApprovals = 0;
      }
      if (!mounted) {
        return;
      }
      setState(() => _notifications = rows);
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error.toString().replaceFirst('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _markAsRead(NotificationModel item) async {
    if (!item.isUnread) {
      return;
    }

    try {
      await widget.api.markNotificationsRead(widget.session.token, [item.id]);
      setState(() {
        _notifications = _notifications
            .map(
              (row) => row.id == item.id
                  ? NotificationModel(
                      id: row.id,
                      type: row.type,
                      title: row.title,
                      body: row.body,
                      status: 'READ',
                      createdAt: row.createdAt,
                      readAt: DateTime.now(),
                      data: row.data,
                    )
                  : row,
            )
            .toList();
      });
    } catch (_) {
      // ignore
    }
  }

  Future<void> _delete(NotificationModel item) async {
    try {
      await widget.api.deleteNotification(widget.session.token, item.id);
      if (!mounted) {
        return;
      }
      setState(() {
        _notifications = _notifications.where((n) => n.id != item.id).toList();
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', '')),
          ),
        );
      }
    }
  }

  Future<void> _openNotification(NotificationModel item) async {
    await _markAsRead(item);

    final conversationId = item.data['conversationId']?.toString();
    if (conversationId != null && conversationId.isNotEmpty) {
      widget.onOpenConversation(conversationId);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_onboardingDone) {
      return NotificationsOnboardingScreen(
        embedded: widget.embedded,
        onSkip: () {
          setState(() {
            _onboardingDone = true;
          });
          _loadNotifications();
        },
        onEnable: () {
          setState(() {
            _onboardingDone = true;
          });
          _loadNotifications();
        },
      );
    }

    final muted = CommunicationPalette.textMuted(context);

    final body = Container(
      decoration: CommunicationPalette.backgroundDecoration(),
      child: _loading
          ? const _NotificationsSkeleton()
          : _error != null
          ? Center(
              child: Text(_error!, style: TextStyle(color: muted)),
            )
          : RefreshIndicator(
              onRefresh: _loadNotifications,
              child: _notifications.isEmpty
                  ? ListView(
                      children: [
                        const SizedBox(height: 120),
                        if (_pendingApprovals > 0)
                          _ApprovalsNotification(
                            count: _pendingApprovals,
                            onTap: () {
                              final shell = AppShellScope.of(context);
                              if (shell != null) {
                                shell.navigate(AppRoutes.approvals);
                              } else {
                                Navigator.of(
                                  context,
                                ).pushNamed(AppRoutes.approvals);
                              }
                            },
                          ),
                        if (_pendingApprovals == 0)
                          const EmptyState(
                            title: 'No notifications yet',
                            message:
                                'Your notifications will appear once received.',
                            icon: Icons.mark_email_read_outlined,
                          ),
                      ],
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      children: [
                        _sectionTitle(context, 'Today'),
                        const SizedBox(height: AppSpacing.s8),
                        if (_pendingApprovals > 0) ...[
                          _ApprovalsNotification(
                            count: _pendingApprovals,
                            onTap: () {
                              final shell = AppShellScope.of(context);
                              if (shell != null) {
                                shell.navigate(AppRoutes.approvals);
                              } else {
                                Navigator.of(
                                  context,
                                ).pushNamed(AppRoutes.approvals);
                              }
                            },
                          ),
                          const SizedBox(height: AppSpacing.s12),
                        ],
                        ..._buildItems(
                          context,
                          _notifications.where(_isToday).toList(),
                        ),
                        const SizedBox(height: AppSpacing.s16),
                        _sectionTitle(context, 'Previously'),
                        const SizedBox(height: AppSpacing.s8),
                        ..._buildItems(
                          context,
                          _notifications.where((n) => !_isToday(n)).toList(),
                        ),
                      ],
                    ),
            ),
    );

    if (widget.embedded) {
      return body;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            onPressed: _loadNotifications,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: body,
    );
  }

  bool _isToday(NotificationModel item) {
    final now = DateTime.now();
    final d = item.createdAt;
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  Widget _sectionTitle(BuildContext context, String label) {
    return Text(label, style: Theme.of(context).textTheme.titleSmall);
  }

  List<Widget> _buildItems(
    BuildContext context,
    List<NotificationModel> items,
  ) {
    final card = CommunicationPalette.card(context);
    final fg = CommunicationPalette.textPrimary(context);
    final muted = CommunicationPalette.textMuted(context);

    if (items.isEmpty) {
      return const [AppCard(child: Text('No items'))];
    }

    return items.map((item) {
      return Dismissible(
        key: ValueKey(item.id),
        direction: DismissDirection.endToStart,
        background: Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.error,
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Icon(
            Icons.delete_outline_rounded,
            color: Theme.of(context).colorScheme.onError,
          ),
        ),
        onDismissed: (_) => _delete(item),
        child: GestureDetector(
          onLongPress: () => _delete(item),
          onTap: () => _openNotification(item),
          child: AppCard(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: item.isUnread
                      ? CommunicationPalette.secondary
                      : CommunicationPalette.primary,
                  child: Text(
                    item.title.isNotEmpty ? item.title[0].toUpperCase() : 'N',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.body,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${item.createdAt.day}/${item.createdAt.month}/${item.createdAt.year}',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                ),
                if (item.isUnread)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: CommunicationPalette.secondary,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }
}

class _NotificationsSkeleton extends StatelessWidget {
  const _NotificationsSkeleton();

  @override
  Widget build(BuildContext context) {
    final card = CommunicationPalette.card(context);

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: 7,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          height: 84,
          decoration: BoxDecoration(
            color: card.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(14),
          ),
        );
      },
    );
  }
}

class _ApprovalsNotification extends StatelessWidget {
  const _ApprovalsNotification({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: CommunicationPalette.secondary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.verified_user_outlined,
              color: CommunicationPalette.secondary,
            ),
          ),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'User approvals pending',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.s4),
                Text(
                  '$count users awaiting approval.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}
