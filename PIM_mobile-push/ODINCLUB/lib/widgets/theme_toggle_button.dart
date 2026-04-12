import 'package:flutter/material.dart';
import '../theme/theme_controller.dart';

class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeController.isDark(context);
    return IconButton(
      icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
      onPressed: ThemeController.toggle,
      tooltip: isDark ? 'Light mode' : 'Dark mode',
    );
  }
}
