import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'dart:ui'; // Added for ImageFilter

// ─── Scenario Data Model ────────────────────────────────────────────────────
class FootballScenario {
  final String id;
  final String situation;
  final String description;
  final String emoji;
  final List<String> options;
  final int correctIndex;

  const FootballScenario({
    required this.id,
    required this.situation,
    required this.description,
    required this.emoji,
    required this.options,
    required this.correctIndex,
  });
}

// ─── Hardcoded Football Scenarios ───────────────────────────────────────────
const List<FootballScenario> _scenarios = [
  FootballScenario(
    id: 'sc_001',
    situation: 'ATTACK: 1v1 KEEPER',
    description: 'Keeper is closing down the angle fast. Teammate is free on the right.',
    emoji: '⚽️🥅',
    options: ['LOW SHOT FAR POST', 'PASS TO TEAMMATE', 'CHIP OVER KEEPER'],
    correctIndex: 1,
  ),
  FootballScenario(
    id: 'sc_002',
    situation: 'DEFENCE: PRESSING',
    description: 'Received ball from keeper. Two strikers pressing. Right back is marked.',
    emoji: '🛡️⚡',
    options: ['CLEAR LONG', 'DRIBBLING OUT', 'PASS TO CENTRE MID'],
    correctIndex: 0,
  ),
  FootballScenario(
    id: 'sc_003',
    situation: 'TRANSITION: 3v2',
    description: 'Counter attack. Wing back overlapping. Defence is narrow.',
    emoji: '🏃💨',
    options: ['PASS TO WING', 'SWITCH PLAY', 'DRIVE INTO BOX'],
    correctIndex: 0,
  ),
  FootballScenario(
    id: 'sc_004',
    situation: 'CORNER: 89th MINUTE',
    description: 'Score 1-1. Corner defending. Ball cleared to you at edge of box.',
    emoji: '🎯📐',
    options: ['SMASH IT LONG', 'CONTROL & PASS', 'RUN TO CORNER FLAG'],
    correctIndex: 0,
  ),
  FootballScenario(
    id: 'sc_005',
    situation: 'FREE KICK: 25m',
    description: 'Final kick of the game. Wall is set deep. Wind is strong from left.',
    emoji: '🕙🔥',
    options: ['POWER SHOT', 'CURL TO FAR POST', 'LAY OFF FOR POWER'],
    correctIndex: 1,
  ),
];

class DecisionTestScreen extends StatefulWidget {
  final void Function(Map<String, dynamic> results) onComplete;
  const DecisionTestScreen({super.key, required this.onComplete});

  @override
  State<DecisionTestScreen> createState() => _DecisionTestScreenState();
}

class _DecisionTestScreenState extends State<DecisionTestScreen> with SingleTickerProviderStateMixin {
  int _scenarioIndex = 0;
  int _timeLeft = 4;
  Timer? _timer;
  DateTime? _questionStartTime;
  bool _isScanPhase = true; 

  int _correctAnswers = 0;
  int _wrongAnswers = 0;
  int _hesitationCount = 0;
  final List<int> _decisionTimes = [];

  bool _answered = false;
  int? _selectedIndex;

  late AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _startRound();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _shakeController.dispose();
    super.dispose();
  }

  void _startRound() {
    _answered = false;
    _selectedIndex = null;
    _isScanPhase = true;
    _timeLeft = 4;
    
    setState(() {});

    // Elite Scan phase: 1.2s to see and digest
    Timer(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      setState(() {
        _isScanPhase = false;
        _questionStartTime = DateTime.now();
        _startCountdown();
      });
    });
  }

  void _startCountdown() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_timeLeft <= 1) {
        t.cancel();
        _handleTimeout();
      } else {
        setState(() => _timeLeft--);
        if (_timeLeft == 1) _shakeController.repeat(reverse: true);
      }
    });
  }

  void _handleTimeout() {
    _shakeController.stop();
    setState(() {
      _answered = true;
      _wrongAnswers++;
      _decisionTimes.add(4000);
    });
    Future.delayed(const Duration(milliseconds: 800), _nextScenario);
  }

  void _onAnswerTap(int index) {
    if (_answered || _isScanPhase) return;
    _timer?.cancel();
    _shakeController.stop();

    final elapsed = DateTime.now().difference(_questionStartTime!).inMilliseconds;
    final isCorrect = index == _scenarios[_scenarioIndex].correctIndex;

    setState(() {
      _answered = true;
      _selectedIndex = index;
      _decisionTimes.add(elapsed);
      if (isCorrect) {
        _correctAnswers++;
      } else {
        _wrongAnswers++;
      }
      if (elapsed > 2500) _hesitationCount++;
    });

    Future.delayed(const Duration(milliseconds: 900), _nextScenario);
  }

  void _nextScenario() {
    if (_scenarioIndex >= _scenarios.length - 1) {
      _submitResults();
    } else {
      setState(() => _scenarioIndex++);
      _startRound();
    }
  }

  void _submitResults() {
    final total = _scenarios.length;
    final avgMs = _decisionTimes.isNotEmpty
        ? (_decisionTimes.reduce((a, b) => a + b) / _decisionTimes.length).round()
        : 4000;
    final accuracy = (_correctAnswers / total * 100).round();

    widget.onComplete({
      'avgDecisionTime': avgMs,
      'correctAnswers': _correctAnswers,
      'wrongAnswers': _wrongAnswers,
      'hesitationCount': _hesitationCount,
      'accuracy': accuracy,
    });
  }

  @override
  Widget build(BuildContext context) {
    final scenario = _scenarios[_scenarioIndex];
    final showOptions = !_isScanPhase;
    
    return Column(
      children: [
        // HUD
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('TACTICAL IQ: ${_scenarioIndex + 1}/5', style: const TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: _timeLeft <= 1 ? Colors.red.withOpacity(0.2) : Colors.white10,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _timeLeft <= 1 ? Colors.red : Colors.white24),
                ),
                child: Text('$_timeLeft s', style: TextStyle(color: _timeLeft <= 1 ? Colors.red : Colors.cyanAccent, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),

        // Deep Immersive Scenario Card
        AnimatedBuilder(
          animation: _shakeController,
          builder: (context, child) {
            double offset = _timeLeft <= 1 ? (sin(_shakeController.value * pi * 10) * 3) : 0;
            return Transform.translate(
              offset: Offset(offset, 0),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  width: double.infinity,
                  height: 220,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.02),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: _timeLeft <= 1 ? Colors.red.withOpacity(0.5) : Colors.cyanAccent.withOpacity(0.1), width: 2),
                  ),
                  child: Stack(
                    children: [
                      // Background Gradient
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.cyanAccent.withOpacity(0.05),
                                Colors.blueAccent.withOpacity(0.02),
                                Colors.purpleAccent.withOpacity(0.05),
                              ],
                            ),
                          ),
                        ),
                      ),
                      
                      // Scenario Info
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(scenario.emoji, style: const TextStyle(fontSize: 80)),
                            const SizedBox(height: 12),
                            Text(scenario.situation, style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 16)),
                            const SizedBox(height: 4),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 30),
                              child: Text(scenario.description, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 11)),
                            ),
                          ],
                        ),
                      ),

                      // Elite Blur Effect (shown after Scan Phase)
                      if (!_isScanPhase)
                        Positioned.fill(
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                            child: Container(
                              color: Colors.black.withOpacity(0.3),
                              child: const Center(
                                child: Text("MEMORY MODE", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 5)),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 30),

        // Options
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Text("DECISION REQUIRED", style: TextStyle(color: Colors.white38, fontSize: 11, letterSpacing: 2, fontWeight: FontWeight.bold)),
                    Spacer(),
                    Icon(Icons.bolt, color: Colors.yellowAccent, size: 14),
                  ],
                ),
                const SizedBox(height: 16),
                if (showOptions)
                  ...List.generate(scenario.options.length, (i) {
                    final isCorrect = _answered && i == scenario.correctIndex;
                    final isSelected = _answered && i == _selectedIndex;
                    
                    return GestureDetector(
                      onTap: () => _onAnswerTap(i),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isCorrect ? Colors.green.withOpacity(0.2) : (isSelected ? Colors.red.withOpacity(0.2) : Colors.white.withOpacity(0.05)),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isCorrect ? Colors.green : (isSelected ? Colors.red : Colors.white12)),
                        ),
                        child: Row(
                          children: [
                            Text(scenario.options[i], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                            const Spacer(),
                            if (isCorrect) const Icon(Icons.check_circle, color: Colors.green, size: 22),
                            if (isSelected && !isCorrect) const Icon(Icons.error, color: Colors.red, size: 22),
                          ],
                        ),
                      ),
                    );
                  })
                else
                  const Expanded(child: Center(child: Text("MEMORIZING FIELD...", style: TextStyle(color: Colors.white24, fontSize: 14, letterSpacing: 2)))),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
