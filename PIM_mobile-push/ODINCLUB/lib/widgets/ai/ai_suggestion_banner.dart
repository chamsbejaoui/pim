import 'package:flutter/material.dart';
import '../../theme/ai_colors.dart';

/// Highlighted banner showing the top AI recommendation.
class AiSuggestionBanner extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onTap;

  const AiSuggestionBanner({
    super.key,
    this.title = 'AI Suggestion',
    required this.message,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AiColors.primary.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AiColors.primary.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AiColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.psychology, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  const SizedBox(height: 2),
                  Text(message,
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.8))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
