import 'package:flutter/material.dart';
import '../ui/components/app_button.dart';
import '../ui/components/app_card.dart';
import '../ui/components/app_section_header.dart';
import '../ui/components/app_text_field.dart';
import '../ui/theme/app_spacing.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _firstName = TextEditingController();
  final TextEditingController _lastName = TextEditingController();
  final TextEditingController _email = TextEditingController();

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSectionHeader(
          title: 'Profile & Settings',
          subtitle: 'Update your personal information.',
        ),
        const SizedBox(height: AppSpacing.s24),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppTextField(controller: _firstName, label: 'First name'),
              const SizedBox(height: AppSpacing.s16),
              AppTextField(controller: _lastName, label: 'Last name'),
              const SizedBox(height: AppSpacing.s16),
              AppTextField(
                controller: _email,
                label: 'Email',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: AppSpacing.s16),
              AppButton(
                label: 'Update Profile',
                onPressed: () {},
                icon: Icons.save_outlined,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
