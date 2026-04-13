import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class ReactionTestScreen extends StatefulWidget {
  final Function(Map<String, int>) onComplete;

  const ReactionTestScreen({super.key, required this.onComplete});

  @override
  State<ReactionTestScreen> createState() => _ReactionTestScreenState();
}

class _ReactionTestScreenState extends State<ReactionTestScreen> with TickerProviderStateMixin {
  final int totalRounds = 15;
  int currentRound = 0;
  List<int> reactionTimes = [];

  bool isWaiting = true;
  bool isGoTarget = true;
  double topPos = 0.5;
  double leftPos = 0.5;
  DateTime? showTime;

  int correctGo = 0;
  int missedGo = 0;
  int commissionErrors = 0; // Tapping on Red (No-Go)
  int correctRejections = 0; // Not tapping on Red (No-Go)

  // Adaptive Difficulty State
  double currentSpawnWindow = 1200.0; // Starting window in MS
  int consecutiveSuccesses = 0;

  Timer? delayTimer;
  Timer? noGoTimer;
  final Random random = Random();
  late AnimationController _pulseController;
  late AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _startNextRound();
  }

  @override
  void dispose() {
    delayTimer?.cancel();
    noGoTimer?.cancel();
    _pulseController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _startNextRound() {
    if (!mounted) return;
    setState(() {
      isWaiting = true;
      noGoTimer?.cancel();
    });

    // Random delay between 800ms and 2.4s
    final delay = Duration(milliseconds: 800 + random.nextInt(1600));
    delayTimer = Timer(delay, () {
      if (!mounted) return;

      setState(() {
        // 75% Go targets, 25% No-Go targets
        isGoTarget = random.nextDouble() < 0.75;
        topPos = 0.2 + (random.nextDouble() * 0.6);
        leftPos = 0.2 + (random.nextDouble() * 0.6);
        isWaiting = false;
        showTime = DateTime.now();
      });

      // For both Go and No-Go, we have a window to react
      noGoTimer = Timer(Duration(milliseconds: currentSpawnWindow.toInt()), () {
        if (!mounted || isWaiting) return;

        if (isGoTarget) {
          _handleMissedGo();
        } else {
          _handleCorrectRejection();
        }
      });
    });
  }

  void _onTargetTap() {
    if (isWaiting || showTime == null) return;

    final elapsed = DateTime.now().difference(showTime!).inMilliseconds;

    if (isGoTarget) {
      reactionTimes.add(elapsed);
      correctGo++;
      consecutiveSuccesses++;
      // Speed up every 3 successes
      if (consecutiveSuccesses % 3 == 0) {
        currentSpawnWindow = max(500, currentSpawnWindow * 0.95);
      }
      _nextStep();
    } else {
      // Error: Tapped on No-Go target
      commissionErrors++;
      consecutiveSuccesses = 0; // Reset streak
      _triggerError();
      // Wait a bit to let the user see the error shake before next round
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) _nextStep();
      });
    }
  }

  void _handleMissedGo() {
    missedGo++;
    consecutiveSuccesses = 0;
    _nextStep();
  }

  void _handleCorrectRejection() {
    correctRejections++;
    consecutiveSuccesses++;
    if (consecutiveSuccesses % 3 == 0) {
      currentSpawnWindow = max(500, currentSpawnWindow * 0.95);
    }
    _nextStep();
  }

  void _triggerError() {
    _shakeController.forward(from: 0.0);
  }

  void _nextStep() {
    currentRound++;
    if (currentRound >= totalRounds) {
      _finishTest();
    } else {
      _startNextRound();
    }
  }

  void _finishTest() {
    if (reactionTimes.isEmpty && correctGo == 0) {
      widget.onComplete({
        'avgMs': 1000,
        'bestMs': 1000,
        'worstMs': 1000,
        'accuracy': 0,
        'commissionErrors': commissionErrors,
      });
      return;
    }

    int avgMs = reactionTimes.isNotEmpty
        ? (reactionTimes.reduce((a, b) => a + b) / reactionTimes.length).round()
        : 800;
    int bestMs = reactionTimes.isNotEmpty ? reactionTimes.reduce(min) : 800;
    int worstMs = reactionTimes.isNotEmpty ? reactionTimes.reduce(max) : 1200;

    // Professional accuracy: (Succeeded trials / Total trials)
    int accuracy = (((correctGo + correctRejections) / totalRounds) * 100).round();

    widget.onComplete({
      'avgMs': avgMs,
      'bestMs': bestMs,
      'worstMs': worstMs,
      'accuracy': accuracy,
      'commissionErrors': commissionErrors,
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color targetColor = isGoTarget ? Colors.cyanAccent : Colors.redAccent;
    final String instructionText = isGoTarget ? "GO! TAP!" : "NO-GO! STOP!";

    return Container(
      color: const Color(0xFF0F172A),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: AnimatedBuilder(
        animation: _shakeController,
        builder: (context, child) {
          // Calculate shake offset - removed isWaiting check to allow shake to finish
          // and increased amplitude for higher impact
          double offset = (sin(_shakeController.value * pi * 10) * 12);

          return Transform.translate(
            offset: Offset(offset, 0),
            child: child,
          );
        },
        child: Stack(
          children: [
            Column(
              children: [
                // Elite HUD
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildInfoColumn("ROUND", "${currentRound + 1}/$totalRounds", Colors.white70),
                      _buildInfoColumn("SPEED", "${currentSpawnWindow.toInt()}ms", Colors.cyanAccent),
                      _buildInfoColumn("ERRORS", "$commissionErrors", Colors.redAccent),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                if (isWaiting)
                  Expanded(
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.02),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.white.withOpacity(0.05)),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ScaleTransition(
                              scale: Tween(begin: 0.9, end: 1.1).animate(_pulseController),
                              child: Container(
                                width: 40, height: 40,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.cyanAccent.withOpacity(0.4), width: 3),
                                  boxShadow: [BoxShadow(color: Colors.cyanAccent.withOpacity(0.1), blurRadius: 20)],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'IDENTIFY THE STIMULUS',
                              style: TextStyle(color: Colors.white24, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 3),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'GO: GREEN | NO-GO: RED',
                              style: TextStyle(color: Colors.cyanAccent, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  const Spacer(),
              ],
            ),

            // Advanced Target
            if (!isWaiting)
              Align(
                alignment: FractionalOffset(leftPos, topPos),
                child: GestureDetector(
                  onTap: _onTargetTap,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            colors: [
                              targetColor.withOpacity(0.4),
                              targetColor.withOpacity(0.1),
                            ],
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(color: targetColor.withOpacity(0.8), width: 4),
                          boxShadow: [
                            BoxShadow(color: targetColor.withOpacity(0.3), blurRadius: 30, spreadRadius: 5),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            isGoTarget ? Icons.bolt : Icons.block_flipped,
                            color: Colors.white,
                            size: 70,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        instructionText,
                        style: TextStyle(
                          color: targetColor,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                          shadows: [Shadow(color: targetColor, blurRadius: 10)],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Visual Grid Background
            IgnorePointer(
              child: Opacity(
                opacity: 0.03,
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 8),
                  itemBuilder: (c, i) => Container(decoration: BoxDecoration(border: Border.all(color: Colors.white))),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w900)),
      ],
    );
  }
}
