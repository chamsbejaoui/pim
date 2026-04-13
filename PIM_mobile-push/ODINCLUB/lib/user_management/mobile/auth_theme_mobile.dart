import 'package:flutter/material.dart';

class AuthPalette {
  static const bg = Color(0xFF030A18);
  static const bg2 = Color(0xFF06142A);
  static const bg3 = Color(0xFF0A2347);
  static const panel = Color(0xAA0A162A);
  static const panelSoft = Color(0x990B1A31);
  static const input = Color(0xCC0A1527);
  static const border = Color(0x334D7DCC);
  static const borderStrong = Color(0x556AA0F6);
  static const text = Color(0xFFEAF2FF);
  static const muted = Color(0xFF8A9AB8);
  static const label = Color(0xFF7588AA);
  static const neonBlue = Color(0xFF1EA2FF);
  static const electric = Color(0xFF3A5BFF);
  static const violet = Color(0xFF7C5CFF);
  static const success = Color(0xFF37D89A);
  static const danger = Color(0xFFFF6E8B);
}

class AuthBackground extends StatelessWidget {
  const AuthBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AuthPalette.bg3, AuthPalette.bg2, AuthPalette.bg],
          stops: [0.0, 0.45, 1.0],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -120,
            left: -80,
            child: _GlowOrb(size: 280, color: Color(0x44298CFF), blur: 90),
          ),
          Positioned(
            top: 180,
            right: -60,
            child: _GlowOrb(size: 220, color: Color(0x223B5EFF), blur: 80),
          ),
          Positioned(
            bottom: -120,
            left: 40,
            child: _GlowOrb(size: 260, color: Color(0x2222AFFF), blur: 90),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    const Color(0x22000000),
                    const Color(0x44000000),
                  ],
                  stops: const [0.0, 0.55, 1.0],
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.color, required this.blur});

  final double size;
  final Color color;
  final double blur;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: color, blurRadius: blur, spreadRadius: blur / 4),
        ],
      ),
    );
  }
}

class AuthBrandHero extends StatelessWidget {
  const AuthBrandHero({
    super.key,
    this.topLabel,
    this.title = 'ODIN',
    this.subtitle = 'AI MATCH ANALYTICS',
    this.center = true,
    this.compact = false,
  });

  final String? topLabel;
  final String title;
  final String subtitle;
  final bool center;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final iconSize = compact ? 56.0 : 88.0;
    return Column(
      crossAxisAlignment: center
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        if (topLabel != null && topLabel!.trim().isNotEmpty) ...[
          Text(
            topLabel!,
            style: const TextStyle(
              color: AuthPalette.neonBlue,
              letterSpacing: 4,
              fontWeight: FontWeight.w700,
              fontSize: 11.5,
            ),
          ),
          SizedBox(height: compact ? 10 : 16),
        ],
        Container(
          width: iconSize,
          height: iconSize,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(compact ? 18 : 24),
            color: const Color(0xCC13234A),
            border: Border.all(color: AuthPalette.borderStrong),
            boxShadow: const [
              BoxShadow(
                color: Color(0x331EA2FF),
                blurRadius: 26,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(
            Icons.sports_soccer_rounded,
            color: AuthPalette.electric,
            size: 44,
          ),
        ),
        SizedBox(height: compact ? 14 : 18),
        Text(
          title,
          style: TextStyle(
            color: AuthPalette.text,
            fontWeight: FontWeight.w800,
            fontSize: compact ? 20 : 30,
            letterSpacing: 0.6,
            shadows: const [
              Shadow(
                color: Color(0x44000000),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          textAlign: center ? TextAlign.center : TextAlign.start,
        ),
        SizedBox(height: compact ? 6 : 8),
        Text(
          subtitle,
          style: TextStyle(
            color: AuthPalette.muted,
            fontWeight: FontWeight.w600,
            letterSpacing: compact ? 2.2 : 3.2,
            fontSize: compact ? 10.5 : 12.5,
          ),
          textAlign: center ? TextAlign.center : TextAlign.start,
        ),
      ],
    );
  }
}

class AuthGlassCard extends StatelessWidget {
  const AuthGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 22,
  });

  final Widget child;
  final EdgeInsets padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AuthPalette.panelSoft,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AuthPalette.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 22,
            offset: Offset(0, 12),
          ),
          BoxShadow(color: Color(0x141EA2FF), blurRadius: 18, spreadRadius: 1),
        ],
      ),
      child: child,
    );
  }
}

InputDecoration authInputDecoration({
  required String label,
  String? hint,
  Widget? prefixIcon,
  Widget? suffixIcon,
  bool dense = false,
}) {
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(18),
    borderSide: const BorderSide(color: AuthPalette.border),
  );
  final focusBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(18),
    borderSide: const BorderSide(color: AuthPalette.borderStrong, width: 1.2),
  );
  return InputDecoration(
    labelText: label,
    hintText: hint,
    labelStyle: const TextStyle(color: AuthPalette.label),
    hintStyle: const TextStyle(color: AuthPalette.muted),
    filled: true,
    fillColor: AuthPalette.input,
    isDense: dense,
    contentPadding: EdgeInsets.symmetric(
      horizontal: 16,
      vertical: dense ? 12 : 16,
    ),
    enabledBorder: border,
    disabledBorder: border,
    focusedBorder: focusBorder,
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: AuthPalette.danger),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: AuthPalette.danger, width: 1.2),
    ),
    prefixIcon: prefixIcon,
    suffixIcon: suffixIcon,
  );
}

class AuthPrimaryButton extends StatelessWidget {
  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF3E8CFF), Color(0xFF3454F0)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x551A68FF),
            blurRadius: 26,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          disabledBackgroundColor: Colors.transparent,
          disabledForegroundColor: const Color(0x99FFFFFF),
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(58),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (loading) ...[
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
            ],
            Text(label),
            if (!loading && icon != null) ...[
              const SizedBox(width: 10),
              Icon(icon, size: 22),
            ],
          ],
        ),
      ),
    );
  }
}

class AuthDividerLabel extends StatelessWidget {
  const AuthDividerLabel({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AuthPalette.border, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: const TextStyle(
              color: AuthPalette.label,
              letterSpacing: 2.2,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ),
        const Expanded(child: Divider(color: AuthPalette.border, thickness: 1)),
      ],
    );
  }
}

class AuthQuickActionTile extends StatelessWidget {
  const AuthQuickActionTile({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Column(
        children: [
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              color: const Color(0x66101E36),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AuthPalette.border),
              boxShadow: const [
                BoxShadow(color: Color(0x191EA2FF), blurRadius: 20),
              ],
            ),
            child: Icon(icon, color: AuthPalette.electric, size: 36),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AuthPalette.muted, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class AuthCircleBackButton extends StatelessWidget {
  const AuthCircleBackButton({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0x660A1527),
          border: Border.all(color: AuthPalette.border),
        ),
        child: const Icon(
          Icons.chevron_left_rounded,
          color: AuthPalette.text,
          size: 28,
        ),
      ),
    );
  }
}

class AuthLinkText extends StatelessWidget {
  const AuthLinkText({
    super.key,
    required this.prefix,
    required this.link,
    required this.onTap,
    this.center = true,
  });

  final String prefix;
  final String link;
  final VoidCallback onTap;
  final bool center;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: center
          ? MainAxisAlignment.center
          : MainAxisAlignment.start,
      children: [
        Text(prefix, style: const TextStyle(color: AuthPalette.muted)),
        GestureDetector(
          onTap: onTap,
          child: Text(
            link,
            style: const TextStyle(
              color: AuthPalette.electric,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class AuthSocialButton extends StatelessWidget {
  const AuthSocialButton({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: const Color(0x44101E36),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AuthPalette.border),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: AuthPalette.text,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ),
      ),
    );
  }
}
