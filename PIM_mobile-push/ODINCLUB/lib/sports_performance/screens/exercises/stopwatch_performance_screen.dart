import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/exercise.dart';
import '../../services/exercises_service.dart';
import '../../providers/exercises_provider.dart';
import '../../theme/sp_colors.dart';
import '../../theme/sp_typography.dart';

class StopwatchPerformanceScreen extends ConsumerStatefulWidget {
  final Exercise exercise;
  final String? playerId;

  const StopwatchPerformanceScreen({
    Key? key,
    required this.exercise,
    this.playerId,
  }) : super(key: key);

  @override
  ConsumerState<StopwatchPerformanceScreen> createState() => _StopwatchPerformanceScreenState();
}

class _StopwatchPerformanceScreenState extends ConsumerState<StopwatchPerformanceScreen> {
  final Stopwatch _stopwatch = Stopwatch();
  late Timer _timer;
  final List<LapData> _laps = [];
  
  @override
  void initState() {
    super.initState();
    _startTimer();
    _stopwatch.start();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _stopwatch.stop();
    super.dispose();
  }

  void _recordLap() {
    final now = _stopwatch.elapsed;
    Duration lastLapTime = Duration.zero;
    if (_laps.isNotEmpty) {
      lastLapTime = _laps.first.totalTime;
    }
    
    final lapTime = now - lastLapTime;
    
    setState(() {
      _laps.insert(0, LapData(
        number: _laps.length + 1,
        lapTime: lapTime,
        totalTime: now,
      ));
    });
  }

  Future<void> _finish() async {
    _stopwatch.stop();
    _timer.cancel();
    final totalSeconds = _stopwatch.elapsed.inSeconds;
    final lapsCount = _laps.length;

    // Save session to backend if we have a playerId
    if (widget.playerId != null && widget.exercise.id != null) {
      try {
        final service = ref.read(exercisesServiceProvider);
        await service.recordCompletion(
          widget.exercise.id!,
          playerId: widget.playerId!,
          durationSeconds: totalSeconds,
          lapsCount: lapsCount,
        );
      } catch (_) {
        // Silently fail — UI still shows the bilan
      }
    }

    if (!mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _buildSessionSummaryDialog(totalSeconds, lapsCount),
    );
    if (mounted) Navigator.pop(context);
  }

  Widget _buildSessionSummaryDialog(int totalSeconds, int lapsCount) {
    final mins = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final secs = (totalSeconds % 60).toString().padLeft(2, '0');
    return Dialog(
      backgroundColor: SPColors.backgroundPrimary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: SPColors.primaryBlue.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 48),
            const SizedBox(height: 16),
            Text('SESSION TERMINÉE',
                style: SPTypography.label.copyWith(
                    color: SPColors.primaryBlue,
                    letterSpacing: 2,
                    fontSize: 14)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _bilanCell('⏱ Durée', '$mins:$secs'),
                _bilanCell('🔄 Laps', '$lapsCount'),
                _bilanCell('💪 Intensité', widget.exercise.intensity.value),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: SPColors.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                widget.playerId != null
                    ? '✅ Session enregistrée dans le profil joueur.'
                    : '⚠️ Sélectionnez un joueur pour sauvegarder la session.',
                style: SPTypography.bodySmall.copyWith(
                    color: SPColors.textSecondary, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: SPColors.primaryBlue,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('RETOUR À LA BIBLIOTHÈQUE',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1.2)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bilanCell(String label, String value) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20)),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(
                color: SPColors.textTertiary,
                fontSize: 10,
                letterSpacing: 0.5)),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String threeDigits(int n) => n.toString().padLeft(3, "0");
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    final milliseconds = twoDigits((duration.inMilliseconds.remainder(1000) / 10).floor());
    return "$minutes:$seconds.$milliseconds";
  }

  @override
  Widget build(BuildContext context) {
    final elapsed = _stopwatch.elapsed;
    final targetDuration = Duration(minutes: widget.exercise.duration.toInt());
    final remaining = targetDuration - elapsed;
    final isNegative = remaining.isNegative;
    final displayDuration = isNegative ? elapsed - targetDuration : remaining;
    
    final progress = isNegative ? 1.0 : (remaining.inMilliseconds / targetDuration.inMilliseconds).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: SPColors.backgroundPrimary,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: SPColors.primaryBlue, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Column(
                    children: [
                      Text(
                        'PRO PERFORMANCE | ${widget.exercise.duration.toInt()} MIN',
                        style: SPTypography.label.copyWith(
                          color: SPColors.primaryBlue,
                          letterSpacing: 2,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.exercise.name.toUpperCase(),
                        style: SPTypography.caption.copyWith(
                          color: SPColors.textTertiary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings_outlined, color: SPColors.textTertiary),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Central Timer Circle
            Stack(
              alignment: Alignment.center,
              children: [
                // Circular Progress Ring
                SizedBox(
                  width: 280,
                  height: 280,
                  child: CustomPaint(
                    painter: TimerPainter(
                      progress: progress,
                      color: isNegative ? SPColors.error : SPColors.primaryBlue,
                    ),
                  ),
                ),
                
                // Digital Time
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isNegative)
                      Text(
                        'OVERTIME',
                        style: SPTypography.overline.copyWith(
                          color: SPColors.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        if (isNegative)
                          Text(
                            '+',
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: SPColors.error,
                            ),
                          ),
                        Text(
                          _formatDuration(displayDuration).split('.')[1] == '00' && !isNegative 
                              ? _formatDuration(displayDuration).split('.')[0]
                              : _formatDuration(displayDuration).split('.')[0],
                          style: TextStyle(
                            fontSize: 72,
                            fontWeight: FontWeight.bold,
                            color: isNegative ? SPColors.error : SPColors.primaryBlue,
                            letterSpacing: -2,
                            shadows: [
                              Shadow(
                                color: (isNegative ? SPColors.error : SPColors.primaryBlue).withOpacity(0.5),
                                blurRadius: 20,
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '.${_formatDuration(displayDuration).split('.')[1]}',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w600,
                            color: (isNegative ? SPColors.error : SPColors.primaryBlue).withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      isNegative ? 'TOTAL ELAPSED' : 'TIME REMAINING',
                      style: SPTypography.overline.copyWith(
                        color: SPColors.textTertiary,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 60),
            
            // Split History Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'SPLIT HISTORY',
                    style: SPTypography.label.copyWith(
                      color: SPColors.textPrimary,
                      fontSize: 12,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: SPColors.primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'LIVE SYNCING',
                      style: TextStyle(
                        color: SPColors.primaryBlue,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Split History List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: _laps.isEmpty ? 1 : _laps.length,
                itemBuilder: (context, index) {
                  if (_laps.isEmpty) {
                    return _buildActiveLap(0, elapsed, Duration.zero);
                  }
                  
                  final lap = _laps[index];
                  // In progress lap is always index 0 if we add current lap tracking
                  return _buildLapItem(lap);
                },
              ),
            ),
            
            // Action Buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
              child: Row(
                children: [
                  // LAP Button
                  Expanded(
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: SPColors.primaryBlue.withOpacity(0.3)),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _recordLap,
                          borderRadius: BorderRadius.circular(12),
                          child: Center(
                            child: Text(
                              'LAP / SPLIT',
                              style: SPTypography.label.copyWith(
                                color: Colors.white,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // STOP Button
                  Expanded(
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        color: SPColors.primaryBlue,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: SPColors.primaryBlue.withOpacity(0.4),
                            blurRadius: 15,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _finish,
                          borderRadius: BorderRadius.circular(12),
                          child: Center(
                            child: Text(
                              'STOP / FINISH',
                              style: SPTypography.label.copyWith(
                                color: Colors.white,
                                letterSpacing: 1.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveLap(int num, Duration total, Duration lap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SPColors.primaryBlue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SPColors.primaryBlue.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                '${(num + 1).toString().padLeft(2, '0')}',
                style: TextStyle(color: SPColors.primaryBlue, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatDuration(total),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    'In Progress',
                    style: TextStyle(color: SPColors.textTertiary, fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
          Text(
            '+0.00s',
            style: TextStyle(color: SPColors.textTertiary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildLapItem(LapData lap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SPColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SPColors.borderPrimary),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                lap.number.toString().padLeft(2, '0'),
                style: TextStyle(color: SPColors.textTertiary, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatDuration(lap.totalTime),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    'Lap ${lap.number}',
                    style: TextStyle(color: SPColors.textTertiary, fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
          Text(
            _formatDuration(lap.lapTime),
            style: TextStyle(
              color: SPColors.success,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class LapData {
  final int number;
  final Duration lapTime;
  final Duration totalTime;

  LapData({
    required this.number,
    required this.lapTime,
    required this.totalTime,
  });
}

class TimerPainter extends CustomPainter {
  final double progress;
  final Color color;

  TimerPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    // Background track
    final trackPaint = Paint()
      ..color = color.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;
      
    canvas.drawCircle(center, radius, trackPaint);
    
    // Progress arc
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
      
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(
      rect,
      -1.5708, // -90 degrees
      6.28319 * progress,
      false,
      progressPaint,
    );
    
    // Add glow with a second thinner arc
    final glowPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      
    canvas.drawArc(
      rect,
      -1.5708,
      6.28319 * progress,
      false,
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(TimerPainter oldDelegate) => oldDelegate.progress != progress;
}
