import 'dart:math';
import 'package:flutter/material.dart';

class FocusTestScreen extends StatefulWidget {
  final void Function(Map<String, int> results) onComplete;
  const FocusTestScreen({super.key, required this.onComplete});

  @override
  State<FocusTestScreen> createState() => _FocusTestScreenState();
}

class ShulteTile {
  final int number;
  final Color color;
  final bool isBlack;
  bool isDone;

  ShulteTile({
    required this.number,
    required this.color,
    required this.isBlack,
    this.isDone = false,
  });
}

class _FocusTestScreenState extends State<FocusTestScreen> {
  List<ShulteTile> tiles = [];
  int currentBlack = 1;
  int currentRed = 13;
  bool expectingBlack = true;
  int errors = 0;
  DateTime? startTime;

  @override
  void initState() {
    super.initState();
    _startTest();
  }

  void _startTest() {
    List<ShulteTile> raw = [];
    // 8 Black numbers (1 to 8)
    for (int i = 1; i <= 8; i++) {
      raw.add(ShulteTile(number: i, color: const Color(0xFF94A3B8), isBlack: true));
    }
    // 8 Red numbers (1 to 8)
    for (int i = 1; i <= 8; i++) {
      raw.add(ShulteTile(number: i, color: Colors.redAccent, isBlack: false));
    }
    raw.shuffle();
    setState(() {
      tiles = raw;
      currentBlack = 1;
      currentRed = 8;
      startTime = DateTime.now();
    });
  }

  void _onTileTap(ShulteTile tile) {
    bool isCorrect = false;

    if (expectingBlack && currentBlack <= 8) {
      if (tile.isBlack && tile.number == currentBlack) {
        isCorrect = true;
        currentBlack++;
        if (currentRed >= 1) expectingBlack = false;
      }
    } else {
      if (!tile.isBlack && tile.number == currentRed) {
        isCorrect = true;
        currentRed--;
        if (currentBlack <= 8) expectingBlack = true;
      }
    }

    if (isCorrect) {
      setState(() => tile.isDone = true);
      if (currentBlack > 8 && currentRed < 1) {
        _finishTest();
      }
    } else {
      setState(() => errors++);
    }
  }

  void _finishTest() {
    final elapsed = DateTime.now().difference(startTime!).inSeconds;
    widget.onComplete({
      'completionTime': elapsed,
      'errors': errors,
    });
  }

  @override
  Widget build(BuildContext context) {
    final targetColor = expectingBlack ? const Color(0xFF94A3B8) : Colors.redAccent;
    final targetNum = expectingBlack ? currentBlack : currentRed;

    return Container(
      color: const Color(0xFF0F172A),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        children: [
          // Unified HUD
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoColumn("ERRORS", "$errors", Colors.redAccent),
                _buildInfoColumn("PROGRESS", "${(tiles.where((t) => t.isDone).length / 16 * 100).round()}%", Colors.cyanAccent),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Glass Active Instruction Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  targetColor.withOpacity(0.1),
                  targetColor.withOpacity(0.02),
                ],
              ),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: targetColor.withOpacity(0.3), width: 2),
              boxShadow: [
                BoxShadow(color: targetColor.withOpacity(0.1), blurRadius: 30, spreadRadius: -10),
              ],
            ),
            child: Column(
              children: [
                Text(
                  expectingBlack ? "BLACK ASCENDING" : "RED DESCENDING",
                  style: TextStyle(color: targetColor, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 3),
                ),
                const SizedBox(height: 8),
                Text(
                  "$targetNum",
                  style: TextStyle(color: targetColor, fontSize: 56, fontWeight: FontWeight.w900, shadows: [
                    Shadow(color: targetColor.withOpacity(0.5), blurRadius: 20),
                  ]),
                ),
                const Text("NEXT TARGET", style: TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Schulte Grid (Premium Tiles)
          Expanded(
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: tiles.length,
              itemBuilder: (context, index) {
                final tile = tiles[index];
                if (tile.isDone) return const SizedBox.shrink();

                return GestureDetector(
                  onTap: () => _onTileTap(tile),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withOpacity(0.08),
                          Colors.white.withOpacity(0.02),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: tile.color.withOpacity(0.4), width: 1.5),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '${tile.number}',
                        style: TextStyle(
                          color: tile.color,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          shadows: [Shadow(color: tile.color.withOpacity(0.4), blurRadius: 8)],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Text(
              "SHIFTER PROTOCOL: Alternate cognitive focus between sequences.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white10, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
            ),
          ),
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
        Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w900)),
      ],
    );
  }
}
