import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../theme/app_theme.dart';

class FootballBallAnimation extends StatefulWidget {
  final double size;
  const FootballBallAnimation({super.key, this.size = 60});

  @override
  State<FootballBallAnimation> createState() => _FootballBallAnimationState();
}

class _FootballBallAnimationState extends State<FootballBallAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.linear,
    ));

    _bounceAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final bounceOffset = math.sin(_bounceAnimation.value * 2 * math.pi) * 10;
        return Transform.translate(
          offset: Offset(0, bounceOffset),
          child: Transform.rotate(
            angle: _rotationAnimation.value,
            child: CustomPaint(
              size: Size(widget.size, widget.size),
              painter: FootballBallPainter(),
            ),
          ),
        );
      },
    );
  }
}

class FootballBallPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw white circle
    final whitePaint = Paint()..color = Colors.white;
    canvas.drawCircle(center, radius, whitePaint);

    // Draw black pentagons and hexagons pattern
    final blackPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Draw pentagon in center
    final pentagonPath = Path();
    final pentagonRadius = radius * 0.3;
    for (int i = 0; i < 5; i++) {
      final angle = (i * 2 * math.pi / 5) - math.pi / 2;
      final x = center.dx + pentagonRadius * math.cos(angle);
      final y = center.dy + pentagonRadius * math.sin(angle);
      if (i == 0) {
        pentagonPath.moveTo(x, y);
      } else {
        pentagonPath.lineTo(x, y);
      }
    }
    pentagonPath.close();
    canvas.drawPath(pentagonPath, blackPaint);

    // Draw hexagons around (simplified as lines)
    for (int i = 0; i < 5; i++) {
      final angle = (i * 2 * math.pi / 5) - math.pi / 2;
      final hexRadius = radius * 0.6;
      final x = center.dx + hexRadius * math.cos(angle);
      final y = center.dy + hexRadius * math.sin(angle);
      
      // Draw hexagon shape (simplified)
      final hexPath = Path();
      for (int j = 0; j < 6; j++) {
        final hexAngle = angle + (j * 2 * math.pi / 6);
        final hexX = x + radius * 0.15 * math.cos(hexAngle);
        final hexY = y + radius * 0.15 * math.sin(hexAngle);
        if (j == 0) {
          hexPath.moveTo(hexX, hexY);
        } else {
          hexPath.lineTo(hexX, hexY);
        }
      }
      hexPath.close();
      canvas.drawPath(hexPath, blackPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class RunningPlayerAnimation extends StatefulWidget {
  final double size;
  const RunningPlayerAnimation({super.key, this.size = 80});

  @override
  State<RunningPlayerAnimation> createState() => _RunningPlayerAnimationState();
}

class _RunningPlayerAnimationState extends State<RunningPlayerAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _runAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat();

    _runAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size * 1.5),
          painter: RunningPlayerPainter(_runAnimation.value),
        );
      },
    );
  }
}

class RunningPlayerPainter extends CustomPainter {
  final double animationValue;

  RunningPlayerPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final headY = size.height * 0.15;
    final bodyY = size.height * 0.4;
    final legY = size.height * 0.7;

    // Head
    final headPaint = Paint()..color = AppTheme.blueFonce;
    canvas.drawCircle(Offset(centerX, headY), size.width * 0.15, headPaint);

    // Body (jersey)
    final bodyPaint = Paint()..color = AppTheme.blueCiel;
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(centerX, bodyY),
        width: size.width * 0.4,
        height: size.height * 0.25,
      ),
      const Radius.circular(8),
    );
    canvas.drawRRect(bodyRect, bodyPaint);

    // Arms (running motion)
    final armPaint = Paint()
      ..color = AppTheme.blueFonce
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    
    final armSwing = math.sin(animationValue * 2 * math.pi) * 0.3;
    // Left arm
    canvas.drawLine(
      Offset(centerX - size.width * 0.2, bodyY - size.height * 0.05),
      Offset(centerX - size.width * 0.3, bodyY + size.height * 0.1 + armSwing * size.height * 0.1),
      armPaint,
    );
    // Right arm
    canvas.drawLine(
      Offset(centerX + size.width * 0.2, bodyY - size.height * 0.05),
      Offset(centerX + size.width * 0.3, bodyY + size.height * 0.1 - armSwing * size.height * 0.1),
      armPaint,
    );

    // Legs (running motion)
    final legPaint = Paint()
      ..color = AppTheme.blueFonce
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;
    
    final legSwing = math.sin(animationValue * 2 * math.pi) * 0.4;
    // Left leg
    canvas.drawLine(
      Offset(centerX - size.width * 0.1, bodyY + size.height * 0.12),
      Offset(centerX - size.width * 0.15, legY + legSwing * size.height * 0.15),
      legPaint,
    );
    // Right leg
    canvas.drawLine(
      Offset(centerX + size.width * 0.1, bodyY + size.height * 0.12),
      Offset(centerX + size.width * 0.15, legY - legSwing * size.height * 0.15),
      legPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
