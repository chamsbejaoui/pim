import 'package:flutter/material.dart';
import '../user_management/models/user_management_models.dart';
import '../ui/navigation/menu_config.dart';
import '../ui/shell/app_shell.dart';

Widget buildRoleHome(SessionModel session) {
  final initialRoute = MenuConfig.defaultRouteForRole(session.role);
  return AppShell(session: session, initialRoute: initialRoute);
}
