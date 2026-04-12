import 'package:flutter/material.dart';
import '../user_management/api/user_management_api.dart';
import '../user_management/mobile/register_mobile_page.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return RegisterMobilePage(
      api: UserManagementApi(),
      onShowLogin: () => Navigator.of(context).pop(),
    );
  }
}
