import 'package:flutter/material.dart';
import '../../ui/components/app_button.dart';
import '../../ui/components/app_card.dart';
import '../../ui/components/app_section_header.dart';
import '../../ui/theme/app_spacing.dart';

class UploadVideoScreen extends StatelessWidget {
  const UploadVideoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSectionHeader(
          title: 'Upload Match Video',
          subtitle: 'Start a new AI analysis by uploading a match video.',
        ),
        const SizedBox(height: AppSpacing.s24),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Video Source',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.s8),
              Text(
                'Select a video file or link to begin analysis. This screen is a placeholder for the upload flow.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.s16),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Choose Video',
                      onPressed: () {},
                      icon: Icons.video_library_outlined,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s12),
                  Expanded(
                    child: AppButton(
                      label: 'Paste Link',
                      onPressed: () {},
                      icon: Icons.link_rounded,
                      variant: AppButtonVariant.outlined,
                    ),
                  ),
                ],
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
                'Analysis Settings',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.s8),
              Text(
                'Configure teams, kits, and tracking options before submission.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.s16),
              AppButton(
                label: 'Submit for Analysis',
                onPressed: () {},
                icon: Icons.auto_awesome_rounded,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
