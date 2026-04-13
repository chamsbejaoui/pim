import 'package:flutter/material.dart';
import '../../communication/screens/chat_room_screen.dart';
import '../../communication/screens/notifications_screen.dart';
import '../../user_management/api/user_management_api.dart';
import '../../user_management/models/user_management_models.dart';

class CommunicationNotificationsShellScreen extends StatelessWidget {
  const CommunicationNotificationsShellScreen({
    super.key,
    required this.session,
  });

  final SessionModel session;

  @override
  Widget build(BuildContext context) {
    return NotificationsScreen(
      api: UserManagementApi(),
      session: session,
      embedded: true,
      onOpenConversation: (conversationId) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ChatRoomScreen(
              api: UserManagementApi(),
              session: session,
              conversationId: conversationId,
              title: 'Conversation',
            ),
          ),
        );
      },
    );
  }
}
