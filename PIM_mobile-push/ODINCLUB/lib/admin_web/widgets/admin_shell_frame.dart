import 'package:flutter/material.dart';
import '../theme/admin_theme.dart';

class AdminShellFrame extends StatelessWidget {
  const AdminShellFrame({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final top = AdminPalette.isDark
        ? AdminPalette.mist
        : const Color(0xFFEAF3FF);
    final bottom = AdminPalette.isDark
        ? const Color(0xFF0A123B)
        : const Color(0xFFF8FAFE);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [top, bottom],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -120,
            left: -80,
            child: _orb(280, AdminPalette.electric.withValues(alpha: 0.14)),
          ),
          Positioned(
            bottom: -160,
            right: -120,
            child: _orb(360, AdminPalette.deep.withValues(alpha: 0.12)),
          ),
          child,
        ],
      ),
    );
  }

  Widget _orb(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size),
      ),
    );
  }
}
