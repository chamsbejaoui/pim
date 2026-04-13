import 'package:flutter/material.dart';
import '../../../models/event_player.dart';
import '../../../theme/sp_colors.dart';
import '../../../theme/sp_typography.dart';

class EventPlayerCard extends StatelessWidget {
  final EventPlayer eventPlayer;
  final VoidCallback onTap;

  const EventPlayerCard({
    super.key,
    required this.eventPlayer,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: SPColors.backgroundSecondary,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: SPColors.borderPrimary),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: SPColors.primaryBlue.withOpacity(0.2),
                shape: BoxShape.circle,
                image: const DecorationImage(
                  image: AssetImage('assets/images/placeholder_player.png'), // Replace with actual image
                  fit: BoxFit.cover,
                ),
              ),
              child: Center(
                child: Text(
                  eventPlayer.player.firstName[0] + eventPlayer.player.lastName[0],
                  style: SPTypography.h5.copyWith(color: SPColors.primaryBlue),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    eventPlayer.player.fullName,
                    style: SPTypography.bodyLarge.copyWith(
                      color: SPColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      _buildTag(eventPlayer.player.position, SPColors.primaryBlueLight),
                      const SizedBox(width: 6),
                      Text(
                        '#${10}', // Jersey number placeholder
                        style: SPTypography.caption.copyWith(color: SPColors.textTertiary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Status / Action
            _buildStatusBadge(eventPlayer.status),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right,
              color: SPColors.textTertiary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text.toUpperCase(),
        style: SPTypography.overline.copyWith(
          color: color,
          fontSize: 9,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(ParticipationStatus status) {
    Color color;
    String text;

    switch (status) {
      case ParticipationStatus.confirmed:
        color = SPColors.success;
        text = 'CONFIRMED';
        break;
      case ParticipationStatus.completed:
        color = SPColors.primaryBlue;
        text = 'COMPLETED';
        break;
      case ParticipationStatus.invited:
        color = SPColors.textTertiary;
        text = 'PENDING';
        break;
      case ParticipationStatus.absent:
        color = SPColors.error;
        text = 'ABSENT';
        break;
    }

    if (status == ParticipationStatus.completed) {
      return Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: SPColors.success.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check, size: 16, color: SPColors.success),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: SPColors.backgroundPrimary,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        text,
        style: SPTypography.overline.copyWith(color: color),
      ),
    );
  }
}
