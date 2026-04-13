import 'package:flutter/material.dart';
import '../../theme/ai_colors.dart';

/// Fixed bottom action bar for selection actions (clear, compare, convocation).
class AiBottomActionBar extends StatelessWidget {
  final int selectedCount;
  final VoidCallback onClearAll;
  final VoidCallback onSendConvocation;
  final VoidCallback? onCompare;

  const AiBottomActionBar({
    super.key,
    required this.selectedCount,
    required this.onClearAll,
    required this.onSendConvocation,
    this.onCompare,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AiColors.backgroundDark.withOpacity(0.8),
        border: const Border(top: BorderSide(color: AiColors.borderDark)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$selectedCount Player${selectedCount != 1 ? 's' : ''} Selected',
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AiColors.textSecondary),
                    ),
                    GestureDetector(
                      onTap: onClearAll,
                      child: const Text('CLEAR ALL',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                              color: AiColors.textTertiary)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (selectedCount == 2 && onCompare != null)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: OutlinedButton.icon(
                          onPressed: onCompare,
                          icon: const Icon(Icons.compare_arrows, size: 18),
                          label: const Text('Compare',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AiColors.success,
                            side: BorderSide(
                                color: AiColors.success.withOpacity(0.5)),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ),
                  Expanded(
                    flex: selectedCount == 2 ? 2 : 1,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: selectedCount > 0 ? 1.0 : 0.5,
                      child: ElevatedButton(
                        onPressed:
                            selectedCount > 0 ? onSendConvocation : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AiColors.primary,
                          disabledBackgroundColor:
                              AiColors.primary.withOpacity(0.3),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.send, color: Colors.white, size: 18),
                            SizedBox(width: 8),
                            Text('Convocation',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
