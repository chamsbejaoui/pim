import 'dart:async';

import 'package:flutter/material.dart';

import '../../user_management/api/user_management_api.dart';
import '../../user_management/models/user_management_models.dart';
import '../communication_theme.dart';
import '../models/communication_models.dart';
import '../permissions.dart';
import '../../ui/components/app_card.dart';
import '../../ui/components/empty_state.dart';
import '../../ui/theme/app_spacing.dart';
import 'chat_room_screen.dart';

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({
    super.key,
    required this.api,
    required this.session,
    this.onOpenNotifications,
    this.onLogout,
    this.embedded = false,
  });

  final UserManagementApi api;
  final SessionModel session;
  final VoidCallback? onOpenNotifications;
  final VoidCallback? onLogout;
  final bool embedded;

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  final TextEditingController _searchController = TextEditingController();

  List<ChatUserModel> _users = [];
  List<ConversationModel> _conversations = [];
  bool _loading = true;
  String? _error;
  StreamSubscription<Map<String, dynamic>>? _chatSub;

  @override
  void initState() {
    super.initState();
    _refresh();
    _subscribeRealtime();
  }

  @override
  void dispose() {
    _chatSub?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final futures = await Future.wait([
        widget.api.getChatUsers(
          widget.session.token,
          search: _searchController.text.trim().isEmpty
              ? null
              : _searchController.text.trim(),
        ),
        widget.api.getConversations(
          widget.session.token,
          search: _searchController.text.trim().isEmpty
              ? null
              : _searchController.text.trim(),
        ),
      ]);

      if (!mounted) {
        return;
      }

      setState(() {
        _users = futures[0] as List<ChatUserModel>;
        _conversations = futures[1] as List<ConversationModel>;
      });
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

  void _subscribeRealtime() {
    _chatSub?.cancel();
    _chatSub = widget.api
        .subscribeSse(token: widget.session.token, path: '/chat/stream')
        .listen((event) {
          final eventType = (event['eventType'] ?? '').toString();
          if (eventType != 'heartbeat') {
            _refresh();
          }
        });
  }

  Future<void> _openDirect(ChatUserModel user) async {
    try {
      final conversation = await widget.api.createDirectConversation(
        widget.session.token,
        user.id,
      );

      if (!mounted) {
        return;
      }

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChatRoomScreen(
            api: widget.api,
            session: widget.session,
            conversationId: conversation.id,
            title: conversation.displayTitle,
          ),
        ),
      );

      _refresh();
    } catch (error) {
      if (mounted) {
        _showError(error.toString());
      }
    }
  }

  Future<void> _openConversation(ConversationModel conversation) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatRoomScreen(
          api: widget.api,
          session: widget.session,
          conversationId: conversation.id,
          title: conversation.displayTitle,
        ),
      ),
    );

    _refresh();
  }

  Future<void> _openQuickActions() async {
    final role = widget.session.role;
    final choices = <String>[];
    if (CommunicationPermissions.canSendAnnouncement(role)) {
      choices.add('announcement');
      choices.add('training');
    }
    if (CommunicationPermissions.canSendMedicalAlert(role)) {
      choices.add('medical');
    }
    if (CommunicationPermissions.canSendEmergency(role)) {
      choices.add('emergency');
    }

    if (choices.isEmpty) {
      return;
    }

    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: CommunicationPalette.card(context),
      builder: (context) {
        final textColor = CommunicationPalette.textPrimary(context);

        return SafeArea(
          child: Wrap(
            children: [
              if (choices.contains('announcement'))
                ListTile(
                  leading: const Icon(Icons.campaign_rounded),
                  title: Text(
                    'Coach announcement',
                    style: TextStyle(color: textColor),
                  ),
                  onTap: () => Navigator.pop(context, 'announcement'),
                ),
              if (choices.contains('training'))
                ListTile(
                  leading: const Icon(Icons.schedule_rounded),
                  title: Text(
                    'Training reminder',
                    style: TextStyle(color: textColor),
                  ),
                  onTap: () => Navigator.pop(context, 'training'),
                ),
              if (choices.contains('medical'))
                ListTile(
                  leading: const Icon(Icons.medical_information_rounded),
                  title: Text(
                    'Medical alert',
                    style: TextStyle(color: textColor),
                  ),
                  onTap: () => Navigator.pop(context, 'medical'),
                ),
              if (choices.contains('emergency'))
                ListTile(
                  leading: const Icon(Icons.warning_amber_rounded),
                  title: Text(
                    'Emergency notification',
                    style: TextStyle(color: textColor),
                  ),
                  onTap: () => Navigator.pop(context, 'emergency'),
                ),
            ],
          ),
        );
      },
    );

    switch (action) {
      case 'announcement':
        await _composeAnnouncement();
      case 'training':
        await _composeTrainingReminder();
      case 'medical':
        await _composeMedicalAlert();
      case 'emergency':
        await _composeEmergency();
      default:
        break;
    }
  }

  Future<void> _composeAnnouncement() async {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();
    final approved = await _composeDialog(
      title: 'New announcement',
      titleController: titleController,
      bodyController: bodyController,
    );

    if (!approved) {
      return;
    }

    try {
      await widget.api.sendAnnouncement(
        token: widget.session.token,
        title: titleController.text.trim(),
        text: bodyController.text.trim(),
        targetRoles: const ['JOUEUR'],
      );
      _showInfo('Announcement sent');
      _refresh();
    } catch (error) {
      _showError(error.toString());
    }
  }

  Future<void> _composeEmergency() async {
    final titleController = TextEditingController(text: 'Emergency');
    final bodyController = TextEditingController();
    final approved = await _composeDialog(
      title: 'Emergency message',
      titleController: titleController,
      bodyController: bodyController,
    );
    if (!approved) {
      return;
    }

    try {
      await widget.api.createEmergencyNotification(
        token: widget.session.token,
        title: titleController.text.trim(),
        body: bodyController.text.trim(),
        severity: 'HIGH',
      );
      _showInfo('Emergency notification sent');
    } catch (error) {
      _showError(error.toString());
    }
  }

  Future<void> _composeMedicalAlert() async {
    final players = _users.where((u) => u.role == 'JOUEUR').toList();
    if (players.isEmpty) {
      _showInfo('No players available in this club');
      return;
    }

    final titleController = TextEditingController(text: 'Medical alert');
    final bodyController = TextEditingController();
    final approved = await _composeDialog(
      title: 'Medical alert',
      titleController: titleController,
      bodyController: bodyController,
    );
    if (!approved) {
      return;
    }

    try {
      await widget.api.createMedicalAlert(
        token: widget.session.token,
        title: titleController.text.trim(),
        body: bodyController.text.trim(),
        targetPlayerIds: players.map((e) => e.id).toList(),
      );
      _showInfo('Medical alert sent');
    } catch (error) {
      _showError(error.toString());
    }
  }

  Future<void> _composeTrainingReminder() async {
    final titleController = TextEditingController(text: 'Training reminder');
    final bodyController = TextEditingController();

    final approved = await _composeDialog(
      title: 'Training reminder',
      titleController: titleController,
      bodyController: bodyController,
    );
    if (!approved) {
      return;
    }

    try {
      await widget.api.createTrainingReminder(
        token: widget.session.token,
        title: titleController.text.trim(),
        body: bodyController.text.trim(),
        scheduleAt: DateTime.now().add(const Duration(minutes: 2)),
        targetRoles: const ['JOUEUR'],
      );
      _showInfo('Training reminder scheduled');
    } catch (error) {
      _showError(error.toString());
    }
  }

  Future<bool> _composeDialog({
    required String title,
    required TextEditingController titleController,
    required TextEditingController bodyController,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final card = CommunicationPalette.card(context);
        final textColor = CommunicationPalette.textPrimary(context);
        return AlertDialog(
          backgroundColor: card,
          title: Text(title, style: TextStyle(color: textColor)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: bodyController,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Message'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Send'),
            ),
          ],
        );
      },
    );

    return confirmed == true &&
        titleController.text.trim().isNotEmpty &&
        bodyController.text.trim().isNotEmpty;
  }

  void _showInfo(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showError(String raw) {
    _showInfo(raw.replaceFirst('Exception: ', ''));
  }

  @override
  Widget build(BuildContext context) {
    final fg = CommunicationPalette.textPrimary(context);
    final muted = CommunicationPalette.textMuted(context);
    final card = CommunicationPalette.card(context);

    final body = Container(
      decoration: CommunicationPalette.backgroundDecoration(),
      child: _loading
          ? const _ChatsSkeleton()
          : _error != null
          ? Center(
              child: Text(_error!, style: TextStyle(color: muted)),
            )
          : RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                children: [
                  TextField(
                    controller: _searchController,
                    onSubmitted: (_) => _refresh(),
                    decoration: InputDecoration(
                      hintText: 'Search in club chats...',
                      hintStyle: TextStyle(color: muted),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: CommunicationPalette.secondary,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          Icons.tune_rounded,
                          color: CommunicationPalette.secondary,
                        ),
                        onPressed: _refresh,
                      ),
                      filled: true,
                      fillColor: card,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 96,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _users.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final user = _users[index];
                        return InkWell(
                          onTap: () => _openDirect(user),
                          borderRadius: BorderRadius.circular(20),
                          child: SizedBox(
                            width: 72,
                            child: Column(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: CommunicationPalette.primary,
                                  child: Text(
                                    user.displayName.isEmpty
                                        ? '?'
                                        : user.displayName[0].toUpperCase(),
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  user.firstName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: fg, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s12),
                  Text(
                    'Recent conversations',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.s8),
                  if (_conversations.isEmpty) ...[
                    const EmptyState(
                      title: 'No conversations yet',
                      message:
                          'Start a direct conversation from the avatar row.',
                      icon: Icons.forum_outlined,
                    ),
                  ] else ...[
                    ..._conversations.map((conversation) {
                      return AppCard(
                        onTap: () => _openConversation(conversation),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: CommunicationPalette.primary,
                              child: Text(
                                conversation.displayTitle.isEmpty
                                    ? '?'
                                    : conversation.displayTitle[0]
                                          .toUpperCase(),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.s12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    conversation.displayTitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: AppSpacing.s4),
                                  Text(
                                    conversation.lastMessagePreview.isEmpty
                                        ? 'No messages yet'
                                        : conversation.lastMessagePreview,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppSpacing.s8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  _timeLabel(conversation.lastMessageAt),
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodySmall?.copyWith(fontSize: 11),
                                ),
                                const SizedBox(height: AppSpacing.s4),
                                if (conversation.unreadCount > 0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: CommunicationPalette.secondary,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Text(
                                      '${conversation.unreadCount}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
    );

    if (widget.embedded) {
      return body;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            onPressed: widget.onOpenNotifications,
            icon: const Icon(Icons.notifications_none_rounded),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip: 'Actions',
            onPressed: _openQuickActions,
            icon: const Icon(Icons.add_circle_outline_rounded),
          ),
          if (widget.onLogout != null)
            IconButton(
              tooltip: 'Logout',
              onPressed: widget.onLogout,
              icon: const Icon(Icons.logout_rounded),
            ),
        ],
      ),
      body: body,
    );
  }

  String _timeLabel(DateTime? dateTime) {
    if (dateTime == null) {
      return '--:--';
    }
    final hh = dateTime.hour.toString().padLeft(2, '0');
    final mm = dateTime.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }
}

class _ChatsSkeleton extends StatelessWidget {
  const _ChatsSkeleton();

  @override
  Widget build(BuildContext context) {
    final card = CommunicationPalette.card(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      children: [
        Container(
          height: 54,
          decoration: BoxDecoration(
            color: card.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 96,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemBuilder: (_, __) => Container(
              width: 72,
              decoration: BoxDecoration(
                color: card.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemCount: 5,
          ),
        ),
        const SizedBox(height: 12),
        ...List.generate(
          5,
          (_) => Container(
            height: 78,
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: card.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ],
    );
  }
}
