import 'package:flutter/material.dart';

import '../user_management/api/user_management_api.dart';
import '../user_management/models/user_management_models.dart';
import 'screens/chat_room_screen.dart';
import 'screens/chats_screen.dart';
import 'screens/notifications_screen.dart';

class CommunicationHomePage extends StatefulWidget {
  const CommunicationHomePage({
    super.key,
    required this.api,
    required this.session,
    this.onLogout,
    this.embedded = false,
  });

  final UserManagementApi api;
  final SessionModel session;
  final VoidCallback? onLogout;
  final bool embedded;

  @override
  State<CommunicationHomePage> createState() => _CommunicationHomePageState();
}

class _CommunicationHomePageState extends State<CommunicationHomePage> {
  Future<void> _openNotifications() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NotificationsScreen(
          api: widget.api,
          session: widget.session,
          onOpenConversation: (conversationId) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ChatRoomScreen(
                  api: widget.api,
                  session: widget.session,
                  conversationId: conversationId,
                  title: 'Conversation',
                ),
              ),
            );
          },
        ),
      ),
    );

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChatsScreen(
      api: widget.api,
      session: widget.session,
      onOpenNotifications: _openNotifications,
      onLogout: widget.onLogout,
      embedded: widget.embedded,
    );
  }
}
