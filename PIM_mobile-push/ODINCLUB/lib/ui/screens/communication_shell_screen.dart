import 'package:flutter/material.dart';
import '../../communication/communication_home.dart';
import '../../user_management/api/user_management_api.dart';
import '../../user_management/models/user_management_models.dart';

class CommunicationShellScreen extends StatelessWidget {
  const CommunicationShellScreen({
    super.key,
    required this.session,
  });

  final SessionModel session;

  @override
  Widget build(BuildContext context) {
    return CommunicationHomePage(
      api: UserManagementApi(),
      session: session,
      embedded: true,
    );
  }
}
