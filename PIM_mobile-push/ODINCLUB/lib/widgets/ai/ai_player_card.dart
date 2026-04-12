import 'dart:ui';
import 'package:flutter/material.dart';
import '../../theme/ai_colors.dart';
import '../../models/ai_player.dart';

/// Glass-morphism player card with AI match percentage badge,
/// tags, and selection checkbox.
class AiPlayerCard extends StatelessWidget {
  final AiPlayer player;
  final bool isSelected;
  final VoidCallback onToggleSelect;
  final VoidCallback? onTap;

  const AiPlayerCard({
    super.key,
    required this.player,
    required this.isSelected,
    required this.onToggleSelect,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final matchPct = player.matchPercentage ?? player.computedMatchPercentage;
    final isElite = player.isEliteMatch || matchPct >= 90;
    final tags = player.tags.isNotEmpty ? player.tags : player.computedTags;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AiColors.glassBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AiColors.glassBorder),
              ),
              child: Stack(
                children: [
                  Row(
                    children: [
                      _buildAvatar(matchPct, isElite),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    player.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.white),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: Checkbox(
                                    value: isSelected,
                                    onChanged: (_) => onToggleSelect(),
                                    fillColor:
                                        WidgetStateProperty.resolveWith((s) {
                                      if (s.contains(WidgetState.selected)) {
                                        return AiColors.primary;
                                      }
                                      return Colors.transparent;
                                    }),
                                    side: const BorderSide(
                                        color: AiColors.borderDark, width: 1.5),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _buildInfoLine(),
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AiColors.textSecondary),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 4,
                              runSpacing: 4,
                              children: [
                                if (player.label == 1)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AiColors.primary,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Text('RECRUITED',
                                        style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.8,
                                            color: Colors.white)),
                                  ),
                                ...tags.map((tag) => _buildTag(tag, false)),
                                if (isElite ||
                                    (player.clusterProfile == 'Elite'))
                                  _buildTag('Elite', true),
                                if (player.clusterProfile != null &&
                                    player.clusterProfile != 'Elite')
                                  _buildTag(player.clusterProfile!, false),
                                if (player.aiRecommendation == 'Yes')
                                  _buildTag('Recommended', true),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (isSelected)
                    Positioned(
                      right: -16,
                      top: -16,
                      bottom: -16,
                      child: Container(width: 4, color: AiColors.primary),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(double matchPct, bool isElite) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 64,
          height: 64,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isElite
                  ? AiColors.primary.withOpacity(0.4)
                  : AiColors.borderDark,
              width: 2,
            ),
          ),
          child: CircleAvatar(
            radius: 28,
            backgroundColor: AiColors.cardDark,
            child: Text(
              player.name.isNotEmpty ? player.name[0].toUpperCase() : '?',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ),
        Positioned(
          bottom: -4,
          right: -4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: matchPct >= 90
                  ? AiColors.primary
                  : Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border:
                  Border.all(color: AiColors.backgroundDark, width: 2),
            ),
            child: Text(
              '${matchPct.round()}%',
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  String _buildInfoLine() {
    final parts = <String>[];
    if (player.age != null) parts.add('${player.age}');
    if (player.club != null) parts.add(player.club!);
    if (player.estimatedValue != null) parts.add('${player.estimatedValue} Est.');
    return parts.join(' • ');
  }

  Widget _buildTag(String label, bool isPrimary) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isPrimary
            ? AiColors.primary.withOpacity(0.15)
            : Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
          color: isPrimary ? AiColors.primary : Colors.white,
        ),
      ),
    );
  }
}
