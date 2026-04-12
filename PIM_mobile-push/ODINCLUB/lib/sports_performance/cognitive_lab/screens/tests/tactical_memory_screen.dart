import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';

enum TacticalPhase { Intro, Scan, Hide, Reconstruct, Result }
enum PawnType { Ally, Enemy, Ball }

class TacticalPawn {
  final String id;
  final PawnType type;
  final Offset targetPosition; // Relative position 0.0 to 1.0 (x, y)
  Offset? currentPosition;

  TacticalPawn({
    required this.id,
    required this.type,
    required this.targetPosition,
    this.currentPosition,
  });
}

class TacticalMemoryScreen extends StatefulWidget {
  final Function(Map<String, dynamic>) onComplete;

  const TacticalMemoryScreen({super.key, required this.onComplete});

  @override
  State<TacticalMemoryScreen> createState() => _TacticalMemoryScreenState();
}

class _TacticalMemoryScreenState extends State<TacticalMemoryScreen> with SingleTickerProviderStateMixin {
  TacticalPhase _phase = TacticalPhase.Intro;
  int _level = 1; // 1: Beginner, 2: Pro, 3: Elite

  List<TacticalPawn> _pawns = [];
  Timer? _phaseTimer;
  int _timeLeft = 0;
  DateTime? _reconstructStartTime;
  
  double _fieldWidth = 0;
  double _fieldHeight = 0;

  @override
  void dispose() {
    _phaseTimer?.cancel();
    super.dispose();
  }

  void _generateLevelConfig() {
    _pawns.clear();
    final random = Random();
    
    int numAllies = 0;
    int numEnemies = 0;
    bool hasBall = false;

    if (_level == 1) { numAllies = 3; numEnemies = 0; hasBall = false; }
    else if (_level == 2) { numAllies = 3; numEnemies = 3; hasBall = true; }
    else { numAllies = 5; numEnemies = 5; hasBall = true; }

    // Generate random positions (avoiding edges)
    for (int i = 0; i < numAllies; i++) {
      _pawns.add(TacticalPawn(
        id: 'ally_$i',
        type: PawnType.Ally,
        targetPosition: Offset(0.2 + random.nextDouble() * 0.6, 0.2 + random.nextDouble() * 0.6),
      ));
    }
    for (int i = 0; i < numEnemies; i++) {
      _pawns.add(TacticalPawn(
        id: 'enemy_$i',
        type: PawnType.Enemy,
        targetPosition: Offset(0.2 + random.nextDouble() * 0.6, 0.2 + random.nextDouble() * 0.6),
      ));
    }
    if (hasBall) {
      _pawns.add(TacticalPawn(
        id: 'ball',
        type: PawnType.Ball,
        targetPosition: Offset(0.3 + random.nextDouble() * 0.4, 0.3 + random.nextDouble() * 0.4),
      ));
    }
  }

  void _startScan() {
    _generateLevelConfig();
    setState(() {
      _phase = TacticalPhase.Scan;
      _timeLeft = 5; // 5 seconds to scan
    });

    _phaseTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_timeLeft > 1) {
        setState(() => _timeLeft--);
      } else {
        timer.cancel();
        _startHide();
      }
    });
  }

  void _startHide() {
    setState(() {
      _phase = TacticalPhase.Hide;
    });

    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      _startReconstruct();
    });
  }

  void _startReconstruct() {
    // Reset positions for the player to drag
    for (var pawn in _pawns) {
      pawn.currentPosition = null; 
    }
    
    setState(() {
      _phase = TacticalPhase.Reconstruct;
      _reconstructStartTime = DateTime.now();
    });
  }

  void _validateReconstruction() {
    if (_pawns.any((p) => p.currentPosition == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Placez tous les éléments sur le terrain", style: TextStyle(color: Colors.white)), backgroundColor: Colors.redAccent),
      );
      return;
    }

    // Calculate errors
    double totalPlayerError = 0;
    int playerCount = 0;
    double ballError = 0;

    for (var pawn in _pawns) {
      // Calculate normalized euclidean distance (0.0 to 1.0 logic translated to pixels)
      final targetX = pawn.targetPosition.dx * _fieldWidth;
      final targetY = pawn.targetPosition.dy * _fieldHeight;
      
      final currentX = pawn.currentPosition!.dx;
      final currentY = pawn.currentPosition!.dy;

      final distance = sqrt(pow(targetX - currentX, 2) + pow(targetY - currentY, 2));
      
      if (pawn.type == PawnType.Ball) {
        ballError = distance;
      } else {
        totalPlayerError += distance;
        playerCount++;
      }
    }

    final avgPlayerError = playerCount > 0 ? totalPlayerError / playerCount : 0;
    final timeTakenMs = DateTime.now().difference(_reconstructStartTime!).inMilliseconds;

    setState(() {
      _phase = TacticalPhase.Result;
    });

    // Send complete after small delay so they see the ghost overlay
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      widget.onComplete({
        'avgDistanceError': avgPlayerError,
        'ballDistanceError': ballError,
        'timeMs': timeTakenMs,
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Column(
          children: [
            if (_phase != TacticalPhase.Intro) _buildHeader(),
            Expanded(
              child: _phase == TacticalPhase.Intro ? _buildIntro() : _buildInteractiveField(),
            ),
            if (_phase == TacticalPhase.Reconstruct) _buildInventory(),
            if (_phase == TacticalPhase.Reconstruct) _buildValidationButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "PHASE TACTIQUE", 
            style: TextStyle(color: Color(0xFF64748B), fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 2, decoration: TextDecoration.none)
          ),
          if (_phase == TacticalPhase.Scan)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: _timeLeft <= 2 ? const Color(0xFFEF4444).withOpacity(0.1) : const Color(0xFF10B981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: _timeLeft <= 2 ? const Color(0xFFEF4444) : const Color(0xFF10B981), width: 1.5),
                boxShadow: [
                   BoxShadow(color: (_timeLeft <= 2 ? const Color(0xFFEF4444) : const Color(0xFF10B981)).withOpacity(0.2), blurRadius: 10)
                ]
              ),
              child: Row(
                children: [
                  Icon(Icons.timer_outlined, color: _timeLeft <= 2 ? const Color(0xFFEF4444) : const Color(0xFF10B981), size: 16),
                  const SizedBox(width: 8),
                  Text(
                    "00:0$_timeLeft", 
                    style: TextStyle(
                      color: _timeLeft <= 2 ? const Color(0xFFEF4444) : const Color(0xFF10B981), 
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      decoration: TextDecoration.none
                    )
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildIntro() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 10),
          const Text("Tactical Recall", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22)),
          const SizedBox(height: 4),
          const Text("Intelligence tactique · Vision de jeu", style: TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          
          // Player Mock Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B).withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: Colors.blueAccent,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(child: Text("KM", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18))),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Joueur Actif", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      Text("Milieu offensif - #10", style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF10B981).withOpacity(0.5)),
                  ),
                  child: const Text("Prêt", style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          
          Text("Sélectionnez un niveau", style: TextStyle(color: Colors.white.withOpacity(0.5), fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 16),
          
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildLevelSelector("Débutant", "3 joueurs · positions simples", 1, const Color(0xFF10B981), true),
                  _buildLevelSelector("Pro", "6 joueurs · adversaires inclus", 2, const Color(0xFF10B981), true),
                  _buildLevelSelector("Elite", "11 joueurs · distraction visuelle", 3, Colors.orangeAccent, true),
                  _buildLevelSelector("Master", "Pions en mouvement · mémoire cinétique", 4, Colors.redAccent, false),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => _startScan(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: const Text('Lancer le test', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelSelector(String title, String subtitle, int level, Color dotColor, bool isEnabled) {
    final isSelected = _level == level;
    
    return GestureDetector(
      onTap: isEnabled ? () => setState(() => _level = level) : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B).withOpacity(isEnabled ? 0.3 : 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF10B981) : Colors.white.withOpacity(0.05),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title, 
                    style: TextStyle(
                      color: isEnabled ? Colors.white : Colors.white24, 
                      fontWeight: FontWeight.bold, 
                      fontSize: 16
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle, 
                    style: TextStyle(
                      color: isEnabled ? Colors.white54 : Colors.white24, 
                      fontSize: 12
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: isEnabled ? dotColor : dotColor.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildInteractiveField() {
    return LayoutBuilder(
      builder: (context, constraints) {
        _fieldWidth = constraints.maxWidth - 48; // Padding
        _fieldHeight = constraints.maxHeight - 40;

        return Center(
          child: Container(
            width: _fieldWidth,
            height: _fieldHeight,
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              color: const Color(0xFF223E2A), // Dark Green Pitch from screenshot
              borderRadius: BorderRadius.circular(16),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: CustomPaint(
                painter: PitchPainter(),
                child: Stack(
                  children: [
                
                if (_phase == TacticalPhase.Hide)
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A).withOpacity(0.9),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: const Color(0xFF10B981))
                      ),
                      child: const Text("RECONSTRUISEZ LA PHASE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 2, decoration: TextDecoration.none)),
                    ),
                  ),

                // Drug Target for Reconstruct Phase
                if (_phase == TacticalPhase.Reconstruct)
                  Positioned.fill(
                    child: DragTarget<TacticalPawn>(
                      onAcceptWithDetails: (details) {
                        // Convert global drop position to local field coordinates
                        final RenderBox renderBox = context.findRenderObject() as RenderBox;
                        
                        // details.offset gives the top-left of the drag feedback
                        // Offset by half of dragged size (44x44) to get exact center position mapping
                        final globalCenter = details.offset + const Offset(22, 22);
                        final localCenter = renderBox.globalToLocal(globalCenter);
                        
                        // localCenter is exactly relative to the Stack field container. No margin subtraction needed.
                        final x = localCenter.dx.clamp(0.0, _fieldWidth);
                        final y = localCenter.dy.clamp(0.0, _fieldHeight);
                        
                        setState(() {
                          details.data.currentPosition = Offset(x, y);
                        });
                      },
                      builder: (context, candidateData, rejectedData) => Container(color: Colors.transparent),
                    ),
                  ),

                // Draw Pawns
                ..._pawns.map((pawn) {
                  const double r = 17.0; // Pawn radius offset
                  
                  if (_phase == TacticalPhase.Scan) {
                    return Positioned(
                      left: pawn.targetPosition.dx * _fieldWidth - r,
                      top: pawn.targetPosition.dy * _fieldHeight - r,
                      child: _buildPawnGraphic(pawn, isGhost: false),
                    );
                  } else if (_phase == TacticalPhase.Reconstruct && pawn.currentPosition != null) {
                    return Positioned(
                      left: pawn.currentPosition!.dx - r,
                      top: pawn.currentPosition!.dy - r,
                      child: Draggable<TacticalPawn>(
                        data: pawn,
                        feedback: _buildPawnGraphic(pawn, isGhost: false, isDragging: true),
                        childWhenDragging: const SizedBox.shrink(),
                        child: _buildPawnGraphic(pawn, isGhost: false),
                      ),
                    );
                  } else if (_phase == TacticalPhase.Result) {
                    return Stack(
                      children: [
                        // Ghost
                        Positioned(
                          left: pawn.targetPosition.dx * _fieldWidth - r,
                          top: pawn.targetPosition.dy * _fieldHeight - r,
                          child: _buildPawnGraphic(pawn, isGhost: true),
                        ),
                        // Current
                        if (pawn.currentPosition != null)
                          Positioned(
                            left: pawn.currentPosition!.dx - r,
                            top: pawn.currentPosition!.dy - r,
                            child: _buildPawnGraphic(pawn, isGhost: false),
                          ),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                }),
              ],
            ),
           ),
          ),
         ),
        );
      },
    );
  }

  double _buildHeaderHeight() {
    return 110; // Estimation
  }

  Widget _buildInventory() {
    final availablePawns = _pawns.where((p) => p.currentPosition == null).toList();
    if (availablePawns.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 80,
      margin: const EdgeInsets.only(bottom: 10),
      child: Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: availablePawns.map((pawn) {
              return Draggable<TacticalPawn>(
                data: pawn,
                feedback: _buildPawnGraphic(pawn, isGhost: false, isDragging: true),
                childWhenDragging: Opacity(opacity: 0.3, child: _buildPawnGraphic(pawn, isGhost: false)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: _buildPawnGraphic(pawn, isGhost: false),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildValidationButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
      child: ElevatedButton(
        onPressed: _validateReconstruction,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.cyanAccent,
          foregroundColor: Colors.black,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: const Text('VALIDER LA PHASE', style: TextStyle(fontWeight: FontWeight.w900)),
      ),
    );
  }

  Widget _buildPawnGraphic(TacticalPawn pawn, {required bool isGhost, bool isDragging = false}) {
    Color color;
    String? label;

    switch (pawn.type) {
      case PawnType.Ally:
        color = const Color(0xFF3B72C4); // Blue from screenshot
        label = 'A';
        break;
      case PawnType.Enemy:
        color = const Color(0xFFCE4A4A); // Red from screenshot
        label = 'D';
        break;
      case PawnType.Ball:
        color = const Color(0xFFEADD85); // Yellow from screenshot
        label = null;
        break;
    }

    if (isGhost) color = color.withOpacity(0.3);

    return Material(
      type: MaterialType.transparency,
      child: Container(
        width: isDragging ? 44 : 34,
        height: isDragging ? 44 : 34,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: pawn.type == PawnType.Ball ? Colors.black26 : Colors.white.withOpacity(0.9), width: isGhost ? 1 : 1.5),
          boxShadow: isGhost || isDragging ? [] : [
            BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 4, offset: const Offset(0, 3)),
          ],
        ),
        child: Center(
          child: label != null
              ? Text(label, style: TextStyle(color: Colors.white.withOpacity(isGhost ? 0.3 : 1.0), fontWeight: FontWeight.bold, fontSize: isDragging ? 20 : 16, decoration: TextDecoration.none))
              : const SizedBox.shrink(),
        ),
      ),
    );
  }
}

class PitchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Field Border
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Center Line
    canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), paint);

    // Center Circle
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), 50, paint);

    // Center Dot
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), 3, paint..style = PaintingStyle.fill);

    // Top Penalty Area
    final penWidth = size.width * 0.6;
    final penHeight = size.height * 0.15;
    canvas.drawRect(Rect.fromLTWH((size.width - penWidth) / 2, 0, penWidth, penHeight), paint..style = PaintingStyle.stroke);

    // Bottom Penalty Area
    canvas.drawRect(Rect.fromLTWH((size.width - penWidth) / 2, size.height - penHeight, penWidth, penHeight), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
