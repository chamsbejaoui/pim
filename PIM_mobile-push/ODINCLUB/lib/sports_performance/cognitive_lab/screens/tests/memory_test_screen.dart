import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class MemoryTestScreen extends StatefulWidget {
  final Function(Map<String, int>) onComplete;

  const MemoryTestScreen({super.key, required this.onComplete});

  @override
  State<MemoryTestScreen> createState() => _MemoryTestScreenState();
}

class _MemoryTestScreenState extends State<MemoryTestScreen> {
  List<int> sequence = [];
  List<int> userSequence = [];
  bool isShowingSequence = false;

  int currentLevel = 3;
  int correctSequences = 0;
  int failures = 0;

  int currentlyLit = -1;
  int distractorLit = -1;

  final Random random = Random();
  Timer? _distractorTimer;

  @override
  void initState() {
    super.initState();
    _startLevel();
  }

  @override
  void dispose() {
    _distractorTimer?.cancel();
    super.dispose();
  }

  void _startLevel() async {
    if (!mounted) return;
    setState(() {
      isShowingSequence = true;
      userSequence = [];
      distractorLit = -1;
    });

    sequence = List.generate(currentLevel, (_) => random.nextInt(9));

    await Future.delayed(const Duration(seconds: 1));
    _startDistractors();

    for (int tile in sequence) {
      if (!mounted) return;
      setState(() => currentlyLit = tile);
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      setState(() => currentlyLit = -1);
      await Future.delayed(const Duration(milliseconds: 250));
    }

    _distractorTimer?.cancel();
    if (!mounted) return;
    setState(() {
      isShowingSequence = false;
      distractorLit = -1;
    });
  }

  void _startDistractors() {
    _distractorTimer?.cancel();
    _distractorTimer = Timer.periodic(const Duration(milliseconds: 400), (timer) {
      if (!mounted || !isShowingSequence) {
        timer.cancel();
        return;
      }
      if (random.nextDouble() < 0.3) {
        setState(() {
          int d = random.nextInt(9);
          if (d != currentlyLit) distractorLit = d;
        });
        Future.delayed(const Duration(milliseconds: 150), () {
          if (mounted) setState(() => distractorLit = -1);
        });
      }
    });
  }

  void _onTileTap(int index) {
    if (isShowingSequence) return;

    setState(() {
      userSequence.add(index);
      currentlyLit = index;
    });

    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) setState(() => currentlyLit = -1);
    });

    int currentIndex = userSequence.length - 1;
    if (userSequence[currentIndex] != sequence[currentIndex]) {
      failures++;
      if (failures >= 3) {
        _finishTest();
      } else {
        _startLevel();
      }
      return;
    }

    if (userSequence.length == sequence.length) {
      correctSequences++;
      currentLevel++;
      if (currentLevel > 7) {
        _finishTest();
      } else {
        Future.delayed(const Duration(milliseconds: 600), _startLevel);
      }
    }
  }

  void _finishTest() {
    widget.onComplete({
      'correctSequences': correctSequences,
      'failures': failures,
      'maxLevel': currentLevel,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0F172A),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        children: [
          // Unified HUD Style
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.white12),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20)],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoColumn("LEVEL", "$currentLevel", Colors.cyanAccent),
                _buildInfoColumn("STRIKES", "$failures/3", Colors.redAccent),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Glass Instruction Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  isShowingSequence ? Colors.orangeAccent.withOpacity(0.12) : Colors.cyanAccent.withOpacity(0.12),
                  Colors.white.withOpacity(0.01),
                ],
              ),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: isShowingSequence ? Colors.orangeAccent.withOpacity(0.3) : Colors.cyanAccent.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isShowingSequence ? Colors.orangeAccent.withOpacity(0.1) : Colors.cyanAccent.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isShowingSequence ? Icons.visibility : Icons.touch_app,
                    color: isShowingSequence ? Colors.orangeAccent : Colors.cyanAccent,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  isShowingSequence ? 'WATCH TARGETS' : 'YOUR TURN',
                  style: TextStyle(
                    color: isShowingSequence ? Colors.orangeAccent : Colors.cyanAccent,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isShowingSequence ? '(IGNORE PURPLE GHOSTS)' : 'REPEAT SEQUENCE',
                  style: const TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
                ),
              ],
            ),
          ),

          const Spacer(),

          // Grid with Premium "Glass Pad" Tiles
          AspectRatio(
            aspectRatio: 1,
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 18,
                mainAxisSpacing: 18,
              ),
              itemCount: 9,
              itemBuilder: (context, index) {
                final isLit = currentlyLit == index;
                final isDistractor = distractorLit == index;

                return GestureDetector(
                  onTap: () => _onTileTap(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          isLit
                              ? Colors.cyanAccent
                              : (isDistractor ? Colors.purpleAccent.withOpacity(0.8) : Colors.white.withOpacity(0.06)),
                          isLit
                              ? Colors.blueAccent
                              : (isDistractor ? Colors.purple.withOpacity(0.4) : Colors.white.withOpacity(0.02)),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isLit ? Colors.white : (isDistractor ? Colors.purpleAccent : Colors.white.withOpacity(0.15)),
                        width: isLit ? 3 : 1.5,
                      ),
                      boxShadow: [
                        if (isLit) BoxShadow(color: Colors.cyanAccent.withOpacity(0.8), blurRadius: 30, spreadRadius: 4),
                        if (isDistractor) BoxShadow(color: Colors.purpleAccent.withOpacity(0.5), blurRadius: 20),
                        if (!isLit && !isDistractor) BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6)),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        isLit ? Icons.bolt : (isDistractor ? Icons.warning_amber_rounded : null),
                        color: isLit ? Colors.white : (isDistractor ? Colors.white70 : Colors.white10),
                        size: isLit ? 36 : 24,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const Spacer(),

          const Text(
            "SPATIAL MEMORY UNDER INTERFERENCE\nProfessional elite cognitive requirement",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white10, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w900)),
      ],
    );
  }
}
