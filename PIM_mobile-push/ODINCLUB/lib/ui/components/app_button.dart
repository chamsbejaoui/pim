import 'package:flutter/material.dart';

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = AppButtonVariant.filled,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AppButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    final child = icon == null
        ? Text(label)
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: 8),
              Text(label),
            ],
          );

    switch (variant) {
      case AppButtonVariant.outlined:
        return OutlinedButton(onPressed: onPressed, child: child);
      case AppButtonVariant.ghost:
        return TextButton(onPressed: onPressed, child: child);
      case AppButtonVariant.filled:
        return ElevatedButton(onPressed: onPressed, child: child);
    }
  }
}

enum AppButtonVariant { filled, outlined, ghost }
