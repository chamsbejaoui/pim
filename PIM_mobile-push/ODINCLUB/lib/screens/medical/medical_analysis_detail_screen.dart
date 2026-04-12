import 'package:flutter/material.dart';
import '../../ui/components/app_button.dart';
import '../../ui/components/app_card.dart';
import '../../ui/components/app_section_header.dart';
import '../../ui/theme/app_spacing.dart';

class MedicalAnalysisDetailScreen extends StatelessWidget {
  const MedicalAnalysisDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSectionHeader(
          title: 'Medical Analysis Detail',
          subtitle: 'Risk, fatigue, and recovery insights for a player.',
        ),
        const SizedBox(height: AppSpacing.s24),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select a player',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.s8),
              Text(
                'Open the Medical Players List to run analysis on a specific player.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.s16),
              AppButton(
                label: 'Go to Medical Players',
                onPressed: () => Navigator.of(context).maybePop(),
                icon: Icons.groups_outlined,
                variant: AppButtonVariant.outlined,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.s16),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Key Metrics',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.s8),
              Text(
                'Risk score, fatigue, and recovery timelines will appear here once a player is selected.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
