import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/player_model.dart';
import '../../models/simulation_player_model.dart';
import '../../models/simulation_result_model.dart';
import '../../models/simulation_start_model.dart';
import '../../models/alert_model.dart';
import '../../services/commentary_service.dart';
import '../../services/match_simulation_service.dart';
import '../../services/simulation_service.dart';
import '../../services/alert_service.dart';
import '../../theme/app_theme.dart';
import '../../ui/theme/app_colors.dart';
import '../../ui/theme/app_spacing.dart';
import '../../widgets/alert_overlay.dart';

class SimulationScreen extends StatefulWidget {
  const SimulationScreen({super.key});

  @override
  State<SimulationScreen> createState() => _SimulationScreenState();
}

class _SimulationScreenState extends State<SimulationScreen>
    with TickerProviderStateMixin {
  static const Duration _simulationDuration = Duration(seconds: 30);

  final SimulationService _simulationService = SimulationService();
  final CommentaryService _commentaryService = CommentaryService();
  final MatchSimulationService _matchSimulationService =
      MatchSimulationService();
  final AlertService _alertService = AlertService.instance;
  final math.Random _random = math.Random();

  SimulationStartModel? _match;
  Future<List<SimulationResultModel>>? _resultsFuture;
  late Future<List<PlayerModel>> _playersFuture;
  final Set<String> _selectedPlayerIds = {};
  String? _errorMessage;

  bool _isStarting = false;
  bool _isRunning = false;
  bool _hasEnded = false;

  StreamSubscription<AlertModel>? _alertSubscription;
  AlertModel? _latestAlert;

  Timer? _commentaryTimer;
  Timer? _commentaryHideTimer;
  Timer? _whistleTimer;
  String _commentaryText = '';
  bool _showCommentary = false;

  int _homeScore = 0;
  int _awayScore = 0;
  int _possessionHome = 52;
  int _shotsHome = 0;
  int _shotsAway = 0;
  int _shotsOnTargetHome = 0;
  int _shotsOnTargetAway = 0;
  String _eventText = 'Kickoff';
  int _eventCooldown = 0;
  int _statTick = 0;
  int _renderTick = 0;
  final ValueNotifier<int> _fieldRepaint = ValueNotifier(0);
  int _possessionHomeTicks = 0;
  int _possessionAwayTicks = 0;
  final List<String> _eventFeed = [];

  Size _fieldSize = Size.zero;
  List<PlayerDot> _teamADots = [];
  List<PlayerDot> _teamBDots = [];
  Offset _ballPosition = Offset.zero;
  PlayerDot? _ballTarget;
  Offset? _ballOrigin;
  Offset? _ballDestination;
  double _ballTravelProgress = 0;
  int _ballTravelFrames = 0;
  int _ballTravelTick = 0;
  Offset _ballCurveOffset = Offset.zero;
  int _ballHoldFrames = 0;
  bool _ballWithTeamA = true;

  AnimationController? _motionController;

  @override
  void initState() {
    super.initState();
    _playersFuture = _simulationService.fetchAvailablePlayers();
    _commentaryService.initialize();
    _alertSubscription = _alertService.stream.listen((alert) {
      if (!mounted) {
        return;
      }
      setState(() {
        _latestAlert = _matchSimulationService.mostSevereAlert ?? alert;
      });
    });
  }

  @override
  void dispose() {
    _commentaryTimer?.cancel();
    _commentaryHideTimer?.cancel();
    _whistleTimer?.cancel();
    _alertSubscription?.cancel();
    _commentaryService.dispose();
    _matchSimulationService.dispose();
    _motionController?.dispose();
    _fieldRepaint.dispose();
    super.dispose();
  }

  Future<void> _startSimulation() async {
    setState(() {
      _isStarting = true;
      _errorMessage = null;
      _resultsFuture = null;
      _match = null;
      _hasEnded = false;
    });

    List<PlayerModel> availablePlayers = const [];
    try {
      availablePlayers = await _simulationService.fetchAvailablePlayers();
      if (!mounted) {
        return;
      }
      final availableIds = availablePlayers.map((player) => player.id).toSet();
      final removed = _selectedPlayerIds
          .where((id) => !availableIds.contains(id))
          .toList();
      if (removed.isNotEmpty) {
        setState(() {
          _selectedPlayerIds.removeAll(removed);
          _playersFuture = Future.value(availablePlayers);
          _isStarting = false;
          _errorMessage =
              'Some selected players are injured or unavailable. Please reselect.';
        });
        return;
      }
      setState(() {
        _playersFuture = Future.value(availablePlayers);
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isStarting = false;
        _errorMessage =
            'Unable to refresh player availability. Please try again.';
      });
      return;
    }

    if (_selectedPlayerIds.length != 11) {
      setState(() {
        _isStarting = false;
        _errorMessage = 'Select exactly 11 players to start the match.';
      });
      return;
    }

    final selectedPlayers = availablePlayers
        .where((player) => _selectedPlayerIds.contains(player.id))
        .toList();

    final warmupStartedAt = DateTime.now();
    try {
      await _matchSimulationService
          .warmup(selectedPlayers)
          .timeout(const Duration(seconds: 4));
    } catch (_) {
      // Ignore warmup failures/timeouts so the simulation can still start.
    }

    final elapsed = DateTime.now().difference(warmupStartedAt);
    const minWarmup = Duration(seconds: 5);
    if (elapsed < minWarmup) {
      await Future.delayed(minWarmup - elapsed);
    }

    if (mounted) {
      setState(() {
        _latestAlert = _matchSimulationService.mostSevereAlert;
      });
    }

    try {
      final match = await _simulationService.startMatch(
        playerIds: _selectedPlayerIds.toList(),
      );
      if (!mounted) {
        return;
      }

      setState(() {
        _match = match;
        _isStarting = false;
      });

      _prepareDots(match.teamA, match.teamB);
      _startAnimation();
    } catch (error) {
      if (!mounted) {
        return;
      }
      final message = error.toString();
      if (message.toLowerCase().contains('injured')) {
        try {
          final availablePlayers = await _simulationService
              .fetchAvailablePlayers();
          if (!mounted) {
            return;
          }
          final availableIds = availablePlayers
              .map((player) => player.id)
              .toSet();
          setState(() {
            _selectedPlayerIds.removeWhere((id) => !availableIds.contains(id));
            _playersFuture = Future.value(availablePlayers);
            _isStarting = false;
            _errorMessage =
                'Some selected players are injured. Please reselect.';
          });
          return;
        } catch (_) {}
      }
      setState(() {
        _isStarting = false;
        _errorMessage = message;
      });
    }
  }

  void _prepareDots(
    List<PlayerModel> teamA,
    List<SimulationPlayerModel> teamB,
  ) {
    final field = _fieldSize;
    if (field == Size.zero) {
      return;
    }

    _teamADots = List.generate(teamA.length, (index) {
      return PlayerDot(
        position: _randomOffset(field, leftBias: true),
        color: AppTheme.danger,
      );
    });

    _teamBDots = List.generate(teamB.length, (index) {
      return PlayerDot(
        position: _randomOffset(field, leftBias: false),
        color: AppTheme.accentBlue,
      );
    });

    _ballTarget = _pickBallTarget();
    _ballPosition =
        _ballTarget?.position ?? Offset(field.width / 2, field.height / 2);
    _ballOrigin = _ballPosition;
    _ballDestination = _ballTarget?.position;
    _ballTravelProgress = 0;
    _ballTravelFrames = 0;
    _ballTravelTick = 0;
    _ballCurveOffset = Offset.zero;
    _ballHoldFrames = 10;
    _ballWithTeamA = _teamADots.contains(_ballTarget);
  }

  Future<void> _startAnimation() async {
    _motionController?.dispose();
    _motionController =
        AnimationController(vsync: this, duration: _simulationDuration)
          ..addListener(_tick)
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              _finishSimulation();
            }
          });

    setState(() {
      _isRunning = true;
      _homeScore = 0;
      _awayScore = 0;
      _possessionHome = 52;
      _shotsHome = 0;
      _shotsAway = 0;
      _shotsOnTargetHome = 0;
      _shotsOnTargetAway = 0;
      _eventText = 'Kickoff';
      _eventCooldown = 0;
      _statTick = 0;
      _possessionHomeTicks = 0;
      _possessionAwayTicks = 0;
      _eventFeed
        ..clear()
        ..add('Kickoff');
    });

    await _commentaryService.ensureInitialized();
    _startCommentary();
    if (_match != null) {
      _matchSimulationService.start(_match!.teamA);
    }
    _motionController?.forward();
  }

  void _tick() {
    if (_fieldSize == Size.zero) {
      return;
    }

    _moveDots(_teamADots, speed: 4.2);
    _moveDots(_teamBDots, speed: 4.6);
    _moveBall();
    _updateCoachStats();
    _fieldRepaint.value = _fieldRepaint.value + 1;

    _renderTick = (_renderTick + 1) % 3;
    if (mounted && _renderTick == 0) {
      setState(() {});
    }
  }

  void _pushEvent(String text) {
    _eventText = text;
    _eventFeed.insert(0, text);
    if (_eventFeed.length > 4) {
      _eventFeed.removeLast();
    }
  }

  void _trackPossession() {
    if (_ballWithTeamA) {
      _possessionHomeTicks += 1;
    } else {
      _possessionAwayTicks += 1;
    }

    final total = _possessionHomeTicks + _possessionAwayTicks;
    if (total > 0 && total % 10 == 0) {
      _possessionHome = ((_possessionHomeTicks / total) * 100).round().clamp(
        35,
        65,
      );
    }
  }

  void _updateCoachStats() {
    _statTick += 1;
    if (_statTick % 12 != 0) {
      return;
    }

    if (_eventCooldown > 0) {
      _eventCooldown -= 1;
      return;
    }

    if (_random.nextDouble() < 0.08) {
      final events = [
        'High press',
        'Quick counter',
        'Final third overload',
        'Wide attack',
        'Dangerous set piece',
      ];
      _pushEvent(events[_random.nextInt(events.length)]);
      _eventCooldown = 12;
    }

    if (_random.nextDouble() < 0.05) {
      final shooter = _ballWithTeamA ? 'Odin' : 'Opponents';
      final keeper = _ballWithTeamA ? 'Opponents' : 'Odin';
      if (_ballWithTeamA) {
        _shotsHome += 1;
      } else {
        _shotsAway += 1;
        _shotsOnTargetAway += 1;
      }
      _pushEvent('Shot on target — $shooter');
      if (_random.nextDouble() < 0.28) {
        if (_ballWithTeamA) {
          _homeScore += 1;
        } else {
          _awayScore += 1;
        }
        _pushEvent('Goal — $shooter scores!');
      } else {
        _pushEvent('Save — $keeper keeper');
      }
      _eventCooldown = 16;
    }
  }

  void _moveBall() {
    if (_ballPosition == Offset.zero) {
      return;
    }

    if (_ballTarget == null) {
      _ballTarget = _pickBallTarget(preferTeamA: _ballWithTeamA);
      if (_ballTarget == null) {
        return;
      }
      _ballPosition = _ballTarget!.position;
      _ballOrigin = _ballPosition;
      _ballDestination = _ballTarget!.position;
      _ballTravelProgress = 0;
      _ballHoldFrames = 8;
      _trackPossession();
      return;
    }

    if (_ballHoldFrames > 0) {
      _ballHoldFrames -= 1;
      _ballPosition = _ballTarget!.position;
      _ballOrigin = _ballPosition;
      _ballDestination = _ballTarget!.position;
      _ballTravelProgress = 0;
      _trackPossession();
      if (_ballHoldFrames == 0) {
        final switchTeam = _random.nextDouble() < 0.25;
        _ballWithTeamA = switchTeam ? !_ballWithTeamA : _ballWithTeamA;
        _ballTarget = _pickBallTarget(
          preferTeamA: _ballWithTeamA,
          exclude: _ballTarget,
        );
        _ballOrigin = _ballPosition;
        _ballDestination = _ballTarget?.position ?? _ballOrigin;
        _ballTravelProgress = 0;
        _ballTravelTick = 0;
        final delta = _ballDestination! - _ballOrigin!;
        final distance = delta.distance;
        _ballTravelFrames = (distance / 4).clamp(14, 40).round();
        _ballCurveOffset = _buildCurveOffset(delta, distance);
      }
      return;
    }

    _ballOrigin ??= _ballPosition;
    _ballDestination ??= _ballTarget!.position;

    final delta = _ballDestination! - _ballOrigin!;
    final distance = delta.distance;

    if (distance < 1) {
      _ballHoldFrames = 6;
      final switchTeam = _random.nextDouble() < 0.25;
      _ballWithTeamA = switchTeam ? !_ballWithTeamA : _ballWithTeamA;
      _ballTarget = _pickBallTarget(
        preferTeamA: _ballWithTeamA,
        exclude: _ballTarget,
      );
      _ballOrigin = _ballPosition;
      _ballDestination = _ballTarget?.position ?? _ballOrigin;
      _ballTravelProgress = 0;
      _trackPossession();
      return;
    }

    if (_ballTravelFrames == 0) {
      _ballTravelFrames = (distance / 4).clamp(14, 40).round();
      _ballTravelTick = 0;
      _ballCurveOffset = _buildCurveOffset(delta, distance);
    }

    _ballTravelTick = (_ballTravelTick + 1).clamp(0, _ballTravelFrames);
    _ballTravelProgress = _ballTravelTick / _ballTravelFrames;
    final eased = Curves.easeInOut.transform(_ballTravelProgress);
    _ballPosition = _quadraticBezier(
      _ballOrigin!,
      _ballDestination!,
      _ballCurveOffset,
      eased,
    );

    if (_ballTravelTick >= _ballTravelFrames) {
      _ballHoldFrames = 6;
      final switchTeam = _random.nextDouble() < 0.25;
      _ballWithTeamA = switchTeam ? !_ballWithTeamA : _ballWithTeamA;
      _ballTarget = _pickBallTarget(
        preferTeamA: _ballWithTeamA,
        exclude: _ballTarget,
      );
      _ballOrigin = _ballPosition;
      _ballDestination = _ballTarget?.position ?? _ballOrigin;
      _ballTravelProgress = 0;
      _ballTravelTick = 0;
      _ballTravelFrames = 0;
      _ballCurveOffset = Offset.zero;
    }
    _trackPossession();
  }

  Offset _buildCurveOffset(Offset delta, double distance) {
    if (distance <= 0.1) {
      return Offset.zero;
    }

    final perp = Offset(-delta.dy, delta.dx);
    final perpNorm = perp / perp.distance;
    final magnitude = (distance * 0.12).clamp(6, 28).toDouble();
    final direction = _random.nextBool() ? 1.0 : -1.0;
    return perpNorm * magnitude * direction;
  }

  Offset _quadraticBezier(
    Offset start,
    Offset end,
    Offset curveOffset,
    double t,
  ) {
    final control = (start + end) / 2 + curveOffset;
    final oneMinus = 1 - t;
    return (start * oneMinus * oneMinus) +
        (control * 2 * oneMinus * t) +
        (end * t * t);
  }

  void _moveDots(List<PlayerDot> dots, {required double speed}) {
    for (final dot in dots) {
      final angle = _random.nextDouble() * math.pi * 2;
      final dx = math.cos(angle) * speed;
      final dy = math.sin(angle) * speed;
      var next = dot.position + Offset(dx, dy);

      if (next.dx < 12) {
        next = Offset(12, next.dy);
      }
      if (next.dx > _fieldSize.width - 12) {
        next = Offset(_fieldSize.width - 12, next.dy);
      }
      if (next.dy < 12) {
        next = Offset(next.dx, 12);
      }
      if (next.dy > _fieldSize.height - 12) {
        next = Offset(next.dx, _fieldSize.height - 12);
      }

      dot.position = next;
    }
  }

  Future<void> _finishSimulation() async {
    if (_hasEnded || _match == null) {
      return;
    }

    _motionController?.stop();
    _hasEnded = true;
    _stopCommentary();
    _matchSimulationService.stop();
    setState(() {
      _isRunning = false;
      _resultsFuture = _simulationService
          .endMatch(
            _match!.matchId,
            stats: {
              'homeScore': _homeScore,
              'awayScore': _awayScore,
              'possessionHome': _possessionHome,
              'shotsHome': _shotsHome,
              'shotsAway': _shotsAway,
              'shotsOnTargetHome': _shotsOnTargetHome,
              'shotsOnTargetAway': _shotsOnTargetAway,
            },
          )
          .timeout(const Duration(seconds: 120));
    });
  }

  void _resetSimulation() {
    setState(() {
      _resultsFuture = null;
      _match = null;
      _hasEnded = false;
      _isRunning = false;
      _errorMessage = null;
      _selectedPlayerIds.clear();
      _teamADots = [];
      _teamBDots = [];
      _ballPosition = Offset.zero;
      _ballTarget = null;
      _ballOrigin = null;
      _ballDestination = null;
      _ballTravelProgress = 0;
      _ballHoldFrames = 0;
      _ballWithTeamA = true;
      _homeScore = 0;
      _awayScore = 0;
      _possessionHome = 52;
      _shotsHome = 0;
      _shotsAway = 0;
      _shotsOnTargetHome = 0;
      _shotsOnTargetAway = 0;
      _eventText = 'Kickoff';
      _eventCooldown = 0;
      _statTick = 0;
      _possessionHomeTicks = 0;
      _possessionAwayTicks = 0;
      _eventFeed.clear();
      _playersFuture = _simulationService.fetchAvailablePlayers();
    });
    _stopCommentary();
    _matchSimulationService.stop();
  }

  void _startCommentary() {
    _commentaryService.startStadiumLoop();
    _emitCommentary(CommentaryEvent.intro);
    _scheduleWhistle();
    _scheduleNextCommentary();
  }

  void _stopCommentary() {
    _commentaryTimer?.cancel();
    _commentaryHideTimer?.cancel();
    _whistleTimer?.cancel();
    _commentaryService.stopStadiumLoop();
    _setCommentaryText('');
  }

  void _scheduleWhistle() {
    _whistleTimer?.cancel();
    _whistleTimer = Timer(const Duration(seconds: 27), () {
      if (!_isRunning) {
        return;
      }
      _commentaryService.playWhistle();
      _emitCommentary(CommentaryEvent.end);
    });
  }

  void _scheduleNextCommentary() {
    _commentaryTimer?.cancel();
    if (!_isRunning) {
      return;
    }
    final delaySeconds = 3 + _random.nextInt(3);
    _commentaryTimer = Timer(Duration(seconds: delaySeconds), () {
      if (!_isRunning) {
        return;
      }
      final event = _pickRandomCommentaryEvent();
      _emitCommentary(event);
      _scheduleNextCommentary();
    });
  }

  CommentaryEvent _pickRandomCommentaryEvent() {
    final roll = _random.nextDouble();
    if (roll < 0.2) {
      return CommentaryEvent.collision;
    }
    if (roll < 0.4) {
      return CommentaryEvent.sprint;
    }
    if (roll < 0.7) {
      return CommentaryEvent.intensity;
    }
    return CommentaryEvent.injury;
  }

  void _emitCommentary(CommentaryEvent event) {
    _commentaryService.playEvent(event);
    final line = _commentaryService.randomLine(event);
    _setCommentaryText(line);
  }

  void _setCommentaryText(String text) {
    if (!mounted) {
      return;
    }
    _commentaryHideTimer?.cancel();
    setState(() {
      _commentaryText = text;
      _showCommentary = text.isNotEmpty;
    });
    if (text.isNotEmpty) {
      _commentaryHideTimer = Timer(const Duration(seconds: 3), () {
        if (!mounted) {
          return;
        }
        setState(() {
          _showCommentary = false;
        });
      });
    }
  }

  void _togglePlayer(PlayerModel player) {
    setState(() {
      if (_selectedPlayerIds.contains(player.id)) {
        _selectedPlayerIds.remove(player.id);
      } else {
        _selectedPlayerIds.add(player.id);
      }
    });
  }

  Offset _randomOffset(Size size, {required bool leftBias}) {
    final half = size.width / 2;
    final minX = leftBias ? 16 : half + 16;
    final maxX = leftBias ? half - 16 : size.width - 16;

    return Offset(
      _random.nextDouble() * (maxX - minX) + minX,
      _random.nextDouble() * (size.height - 32) + 16,
    );
  }

  PlayerDot? _pickBallTarget({bool? preferTeamA, PlayerDot? exclude}) {
    final preferred = preferTeamA == null
        ? [..._teamADots, ..._teamBDots]
        : (preferTeamA ? _teamADots : _teamBDots);
    final allDots = [..._teamADots, ..._teamBDots];
    final source = preferred.isNotEmpty ? preferred : allDots;
    if (source.isEmpty) {
      return null;
    }

    if (exclude == null || source.length == 1) {
      return source[_random.nextInt(source.length)];
    }

    PlayerDot candidate = source[_random.nextInt(source.length)];
    int attempts = 0;
    while (candidate == exclude && attempts < 6) {
      candidate = source[_random.nextInt(source.length)];
      attempts += 1;
    }
    return candidate;
  }

  String _remainingTimeLabel() {
    final controller = _motionController;
    if (controller == null) {
      return '00:30';
    }
    final remainingSeconds =
        (_simulationDuration.inSeconds * (1 - controller.value))
            .ceil()
            .clamp(0, _simulationDuration.inSeconds)
            .toInt();
    final minutes = (remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (remainingSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(gradient: AppTheme.appGradient),
      child: SafeArea(
        top: false,
        child: Stack(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 450),
              child: _resultsFuture != null
                  ? _ResultsView(
                      resultsFuture: _resultsFuture!,
                      onReset: _resetSimulation,
                      summary: MatchSummary(
                        homeScore: _homeScore,
                        awayScore: _awayScore,
                        possessionHome: _possessionHome,
                        shotsHome: _shotsHome,
                        shotsAway: _shotsAway,
                        shotsOnTargetHome: _shotsOnTargetHome,
                        shotsOnTargetAway: _shotsOnTargetAway,
                      ),
                    )
                  : _SimulationView(
                      isStarting: _isStarting,
                      isRunning: _isRunning,
                      errorMessage: _errorMessage,
                      fieldBuilder: _buildField,
                      onStart: _startSimulation,
                      countdown: _remainingTimeLabel(),
                      playersFuture: _playersFuture,
                      selectedIds: _selectedPlayerIds,
                      onTogglePlayer: _togglePlayer,
                      homeScore: _homeScore,
                      awayScore: _awayScore,
                      possessionHome: _possessionHome,
                      shotsHome: _shotsHome,
                      shotsAway: _shotsAway,
                      shotsOnTargetHome: _shotsOnTargetHome,
                      shotsOnTargetAway: _shotsOnTargetAway,
                      eventText: _eventText,
                      eventFeed: _eventFeed,
                      commentaryText: _commentaryText,
                      showCommentary: _showCommentary,
                      latestAlert: _latestAlert,
                    ),
            ),
            AlertOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildField(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        if (size != _fieldSize && size.width > 0 && size.height > 0) {
          _fieldSize = size;
          if (_match != null && _teamADots.isEmpty && _teamBDots.isEmpty) {
            _prepareDots(_match!.teamA, _match!.teamB);
          }
        }

        return RepaintBoundary(
          child: CustomPaint(
            painter: _FieldPainter(
              teamADots: _teamADots,
              teamBDots: _teamBDots,
              ballPosition: _ballPosition,
              ballTarget: _ballTarget?.position,
              repaint: _fieldRepaint,
            ),
            child: const SizedBox.expand(),
          ),
        );
      },
    );
  }
}

class _SimulationView extends StatelessWidget {
  const _SimulationView({
    required this.isStarting,
    required this.isRunning,
    required this.errorMessage,
    required this.fieldBuilder,
    required this.onStart,
    required this.countdown,
    required this.playersFuture,
    required this.selectedIds,
    required this.onTogglePlayer,
    required this.homeScore,
    required this.awayScore,
    required this.possessionHome,
    required this.shotsHome,
    required this.shotsAway,
    required this.shotsOnTargetHome,
    required this.shotsOnTargetAway,
    required this.eventText,
    required this.eventFeed,
    required this.commentaryText,
    required this.showCommentary,
    required this.latestAlert,
  });

  final bool isStarting;
  final bool isRunning;
  final String? errorMessage;
  final WidgetBuilder fieldBuilder;
  final VoidCallback onStart;
  final String countdown;
  final Future<List<PlayerModel>> playersFuture;
  final Set<String> selectedIds;
  final ValueChanged<PlayerModel> onTogglePlayer;
  final int homeScore;
  final int awayScore;
  final int possessionHome;
  final int shotsHome;
  final int shotsAway;
  final int shotsOnTargetHome;
  final int shotsOnTargetAway;
  final String eventText;
  final List<String> eventFeed;
  final String commentaryText;
  final bool showCommentary;
  final AlertModel? latestAlert;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('simulation-view'),
      children: [
        if (!isRunning)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.s16,
              AppSpacing.s16,
              AppSpacing.s16,
              AppSpacing.s12,
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Kick off a 30-second match simulation',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                ElevatedButton(
                  onPressed: isStarting || selectedIds.length != 11
                      ? null
                      : onStart,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: isStarting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.white,
                          ),
                        )
                      : Text('Start Match Simulation'),
                ),
              ],
            ),
          ),
        if (!isRunning)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _SelectionCard(
              playersFuture: playersFuture,
              selectedIds: selectedIds,
              onTogglePlayer: onTogglePlayer,
            ),
          ),
        if (errorMessage != null && errorMessage!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _InlineError(message: errorMessage!),
          ),
        if (isRunning)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _LiveAlertPanel(alert: latestAlert),
          ),
        const SizedBox(height: 12),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 720;
              final field = ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    border: Border.all(color: AppTheme.cardBorder),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(child: fieldBuilder(context)),
                      Positioned(
                        top: 12,
                        left: 12,
                        right: 12,
                        child: _ScoreboardBar(
                          isRunning: isRunning,
                          countdown: countdown,
                          homeScore: homeScore,
                          awayScore: awayScore,
                          homeLabel: 'Odin',
                          awayLabel: 'Opponents',
                        ),
                      ),
                      Positioned(
                        top: 70,
                        left: 16,
                        right: 16,
                        child: _LiveCommentaryBanner(
                          text: commentaryText,
                          isVisible: showCommentary && isRunning,
                        ),
                      ),
                    ],
                  ),
                ),
              );

              if (isWide) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Row(
                    children: [
                      _SideStatsColumn(
                        title: 'Odin',
                        possession: possessionHome,
                        shots: shotsHome,
                        chances: shotsOnTargetHome,
                        alignRight: false,
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: field),
                      const SizedBox(width: 12),
                      _SideStatsColumn(
                        title: 'Opponents',
                        possession: 100 - possessionHome,
                        shots: shotsAway,
                        chances: shotsOnTargetAway,
                        alignRight: true,
                      ),
                    ],
                  ),
                );
              }

              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  children: [
                    Expanded(child: field),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _SideStatsColumn(
                            title: 'Odin',
                            possession: possessionHome,
                            shots: shotsHome,
                            chances: shotsOnTargetHome,
                            alignRight: false,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _SideStatsColumn(
                            title: 'Opponents',
                            possession: 100 - possessionHome,
                            shots: shotsAway,
                            chances: shotsOnTargetAway,
                            alignRight: true,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _LiveAlertPanel extends StatelessWidget {
  const _LiveAlertPanel({required this.alert});

  final AlertModel? alert;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final statusColor = alert == null
        ? AppTheme.textMuted
        : _accentColor(alert!.status);
    final surface = AppTheme.surface;
    final subtitle = alert == null
        ? 'Monitoring player load and fatigue...'
        : alert!.message;
    final reasons = _reasonText(alert);
    final statLine = alert == null ? null : _statLine(alert!);
    final detailLine = alert == null ? null : _detailLine(alert!);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: statusColor.withOpacity(0.35)),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.2),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.14),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: statusColor.withOpacity(0.4)),
            ),
            child: Text(
              alert?.title ?? 'Live alerts',
              style: textTheme.labelMedium?.copyWith(
                color: statusColor,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert?.playerName ?? 'No critical alerts yet',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (statLine != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    statLine,
                    style: textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
                if (detailLine != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    detailLine,
                    style: textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
                if (reasons != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    reasons,
                    style: textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            alert == null ? '--' : '${(alert!.risk * 100).round()}%',
            style: textTheme.labelLarge?.copyWith(
              color: statusColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Color _accentColor(AlertStatus status) {
    switch (status) {
      case AlertStatus.injured:
        return AppTheme.danger;
      case AlertStatus.warning:
        return AppTheme.warning;
      case AlertStatus.safe:
        return AppTheme.success;
    }
  }

  String? _reasonText(AlertModel? alert) {
    if (alert == null || alert.reasons.isEmpty) {
      return null;
    }
    final trimmed = alert.reasons.where((reason) => reason.trim().isNotEmpty);
    if (trimmed.isEmpty) {
      return null;
    }
    return trimmed.take(2).join(' • ');
  }

  String _statLine(AlertModel alert) {
    return 'Injury probability ${(alert.risk * 100).round()}% • '
        'Load ${alert.load.round()} • Fatigue ${alert.fatigue.round()}';
  }

  String _detailLine(AlertModel alert) {
    final parts = <String>[];
    if (alert.severity != null && alert.severity!.trim().isNotEmpty) {
      parts.add('Severity ${alert.severity}');
    }
    if (alert.recoveryDays != null && alert.recoveryDays! > 0) {
      parts.add('Recovery ${alert.recoveryDays}d');
    }
    if (alert.injuryType != null && alert.injuryType!.trim().isNotEmpty) {
      parts.add('Type ${alert.injuryType}');
    }
    if (parts.isEmpty) {
      return 'Minutes ${alert.minutes}';
    }
    return parts.join(' • ');
  }
}

class _SelectionCard extends StatelessWidget {
  const _SelectionCard({
    required this.playersFuture,
    required this.selectedIds,
    required this.onTogglePlayer,
  });

  final Future<List<PlayerModel>> playersFuture;
  final Set<String> selectedIds;
  final ValueChanged<PlayerModel> onTogglePlayer;

  String? _lastMatchLabel(PlayerModel player) {
    final playedAt = player.lastMatchAt;
    if (playedAt == null) {
      return null;
    }

    final diff = DateTime.now().difference(playedAt);
    if (diff.inMinutes < 60) {
      return 'Played ${diff.inMinutes}m ago';
    }
    if (diff.inHours < 24) {
      return 'Played ${diff.inHours}h ago';
    }
    return 'Played ${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Select your 11 players',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.primaryBlue.withOpacity(0.4),
                  ),
                ),
                child: Text(
                  '${selectedIds.length}/11',
                  style: TextStyle(
                    color: AppTheme.primaryBlue,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<PlayerModel>>(
            future: playersFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Padding(
                  padding: const EdgeInsets.all(12),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.accentBlue,
                    ),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Text(
                  'Unable to load players for selection.',
                  style: TextStyle(color: AppTheme.textSecondary),
                );
              }

              final players = snapshot.data ?? [];
              if (players.isEmpty) {
                return Text(
                  'No players available.',
                  style: TextStyle(color: AppTheme.textSecondary),
                );
              }

              return SizedBox(
                height: 180,
                child: ListView.separated(
                  itemCount: players.length,
                  separatorBuilder: (_, __) =>
                      Divider(height: 1, color: AppTheme.cardBorder),
                  itemBuilder: (context, index) {
                    final player = players[index];
                    final isSelected = selectedIds.contains(player.id);
                    final isInjured = player.isInjured == true;
                    final selectionLocked =
                        !isSelected && selectedIds.length >= 11;
                    final playedLabel = _lastMatchLabel(player);

                    return CheckboxListTile(
                      value: isSelected,
                      dense: true,
                      activeColor: AppTheme.primaryBlue,
                      checkboxShape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      onChanged: selectionLocked || isInjured
                          ? null
                          : (_) => onTogglePlayer(player),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              player.name,
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          if (isInjured)
                            _InjuryBadge(
                              label: player.lastInjuryType ?? 'Injured',
                            )
                          else if (playedLabel != null)
                            _PlayedBadge(label: playedLabel),
                        ],
                      ),
                      subtitle: isInjured
                          ? Text(
                              'Unavailable for selection',
                              style: TextStyle(color: AppTheme.textSecondary),
                            )
                          : null,
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PlayedBadge extends StatelessWidget {
  const _PlayedBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.accentBlue.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.accentBlue.withOpacity(0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: AppTheme.accentBlue,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _InjuryBadge extends StatelessWidget {
  const _InjuryBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.danger.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.danger.withOpacity(0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: AppTheme.danger,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _OverlayCard extends StatelessWidget {
  const _OverlayCard({
    required this.isRunning,
    required this.countdown,
    required this.homeScore,
    required this.awayScore,
    required this.possessionHome,
    required this.shotsHome,
    required this.shotsAway,
    required this.shotsOnTargetHome,
    required this.shotsOnTargetAway,
    required this.eventText,
    required this.eventFeed,
  });

  final bool isRunning;
  final String countdown;
  final int homeScore;
  final int awayScore;
  final int possessionHome;
  final int shotsHome;
  final int shotsAway;
  final int shotsOnTargetHome;
  final int shotsOnTargetAway;
  final String eventText;
  final List<String> eventFeed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceAlt.withOpacity(0.92),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
        boxShadow: [
          BoxShadow(
            color: AppTheme.textPrimary.withOpacity(0.22),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _TeamBadge(color: AppTheme.danger, label: 'Odin'),
              const SizedBox(width: 8),
              Text(
                '$homeScore - $awayScore',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 8),
              _TeamBadge(color: AppTheme.accentBlue, label: 'Opponents'),
              const Spacer(),
              _LivePill(isLive: isRunning),
              const SizedBox(width: 6),
              _CountdownBadge(label: countdown),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Possession',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: possessionHome / 100,
                    minHeight: 5,
                    backgroundColor: AppTheme.surfaceAlt,
                    color: AppTheme.danger,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '$possessionHome%',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _StatPill(label: 'Shots', value: '$shotsHome / $shotsAway'),
              const SizedBox(width: 6),
              _StatPill(
                label: 'On target',
                value: '$shotsOnTargetHome / $shotsOnTargetAway',
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            eventText,
            style: TextStyle(
              color: AppTheme.accentBlue,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          if (eventFeed.isNotEmpty) ...[
            const SizedBox(height: 4),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: eventFeed
                  .take(2)
                  .map(
                    (event) => Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '• $event',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _ScoreboardBar extends StatelessWidget {
  const _ScoreboardBar({
    required this.isRunning,
    required this.countdown,
    required this.homeScore,
    required this.awayScore,
    required this.homeLabel,
    required this.awayLabel,
  });

  final bool isRunning;
  final String countdown;
  final int homeScore;
  final int awayScore;
  final String homeLabel;
  final String awayLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryBlue.withOpacity(0.55),
            AppTheme.accentBlue.withOpacity(0.55),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Row(
        children: [
          _TeamDot(label: homeLabel, color: AppTheme.danger),
          const SizedBox(width: 8),
          Text(
            homeLabel.toUpperCase(),
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const Spacer(),
          Text(
            '$homeScore - $awayScore',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          const Spacer(),
          Text(
            awayLabel.toUpperCase(),
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 8),
          _TeamDot(label: awayLabel, color: AppTheme.accentBlue),
          const SizedBox(width: 10),
          _LivePill(isLive: isRunning),
          const SizedBox(width: 8),
          _CountdownBadge(label: countdown),
        ],
      ),
    );
  }
}

class _TeamDot extends StatelessWidget {
  const _TeamDot({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _SideStatsColumn extends StatelessWidget {
  const _SideStatsColumn({
    required this.title,
    required this.possession,
    required this.shots,
    required this.chances,
    required this.alignRight,
  });

  final String title;
  final int possession;
  final int shots;
  final int chances;
  final bool alignRight;

  @override
  Widget build(BuildContext context) {
    final align = alignRight
        ? CrossAxisAlignment.end
        : CrossAxisAlignment.start;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: align,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _SideStat(label: 'Possession %', value: possession.toString()),
          const SizedBox(height: 12),
          _SideStat(label: 'Shots', value: shots.toString()),
          const SizedBox(height: 12),
          _SideStat(label: 'Chances', value: chances.toString()),
        ],
      ),
    );
  }
}

class _SideStat extends StatelessWidget {
  const _SideStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _TeamBadge extends StatelessWidget {
  const _TeamBadge({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _LivePill extends StatelessWidget {
  const _LivePill({required this.isLive});

  final bool isLive;

  @override
  Widget build(BuildContext context) {
    final color = isLive ? AppTheme.success : AppTheme.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        isLive ? 'Live' : 'Ready',
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _CountdownBadge extends StatelessWidget {
  const _CountdownBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: AppTheme.primaryBlue,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _LiveCommentaryBanner extends StatelessWidget {
  const _LiveCommentaryBanner({required this.text, required this.isVisible});

  final String text;
  final bool isVisible;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: isVisible && text.isNotEmpty ? 1 : 0,
      duration: const Duration(milliseconds: 300),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        child: text.isEmpty
            ? const SizedBox.shrink()
            : Container(
                key: ValueKey(text),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceAlt.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.cardBorder),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.textPrimary.withOpacity(0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.mic, color: AppTheme.accentBlue, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Live Commentary',
                      style: TextStyle(
                        color: AppTheme.accentBlue,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        text,
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _FieldPainter extends CustomPainter {
  _FieldPainter({
    required this.teamADots,
    required this.teamBDots,
    required this.ballPosition,
    required this.ballTarget,
    required Listenable repaint,
  }) : super(repaint: repaint);

  final List<PlayerDot> teamADots;
  final List<PlayerDot> teamBDots;
  final Offset ballPosition;
  final Offset? ballTarget;

  @override
  void paint(Canvas canvas, Size size) {
    final fieldPaint = Paint()
      ..color = const Color(0xFF0A2A6B)
      ..style = PaintingStyle.fill;

    final stripePaint = Paint()
      ..color = const Color(0xFF0C327B)
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = const Color(0xFF82B5FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final standPaint = Paint()
      ..color = const Color(0xFF08122F)
      ..style = PaintingStyle.fill;

    canvas.drawRect(Offset.zero & size, fieldPaint);

    final standHeight = size.height * 0.08;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, standHeight), standPaint);
    canvas.drawRect(
      Rect.fromLTWH(0, size.height - standHeight, size.width, standHeight),
      standPaint,
    );

    final stripeWidth = size.width / 8;
    for (int i = 0; i < 8; i += 2) {
      canvas.drawRect(
        Rect.fromLTWH(
          i * stripeWidth,
          standHeight,
          stripeWidth,
          size.height - standHeight * 2,
        ),
        stripePaint,
      );
    }

    final midX = size.width / 2;
    canvas.drawLine(
      Offset(midX, standHeight),
      Offset(midX, size.height - standHeight),
      linePaint,
    );
    canvas.drawCircle(Offset(midX, size.height / 2), 48, linePaint);

    final penaltyWidth = size.width * 0.12;
    final penaltyHeight = size.height * 0.32;
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.34, penaltyWidth, penaltyHeight),
      linePaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        size.width - penaltyWidth,
        size.height * 0.34,
        penaltyWidth,
        penaltyHeight,
      ),
      linePaint,
    );

    _drawDots(canvas, teamADots);
    _drawDots(canvas, teamBDots);
    _drawPassLane(canvas);
    _drawBall(canvas);
  }

  void _drawDots(Canvas canvas, List<PlayerDot> dots) {
    for (final dot in dots) {
      final paint = Paint()
        ..color = dot.color.withOpacity(0.9)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(dot.position, 6.5, paint);
      canvas.drawCircle(
        dot.position,
        10,
        paint..color = dot.color.withOpacity(0.15),
      );
    }
  }

  void _drawBall(Canvas canvas) {
    if (ballPosition == Offset.zero) {
      return;
    }

    final ballPaint = Paint()
      ..color = AppColors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(ballPosition, 6, ballPaint);
    canvas.drawCircle(
      ballPosition,
      10,
      ballPaint..color = AppColors.white.withOpacity(0.18),
    );
  }

  void _drawPassLane(Canvas canvas) {
    if (ballPosition == Offset.zero || ballTarget == null) {
      return;
    }

    final lanePaint = Paint()
      ..color = AppColors.white.withOpacity(0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawLine(ballPosition, ballTarget!, lanePaint);
  }

  @override
  bool shouldRepaint(covariant _FieldPainter oldDelegate) {
    return true;
  }
}

class PlayerDot {
  PlayerDot({required this.position, required this.color});

  Offset position;
  final Color color;
}

class MatchSummary {
  const MatchSummary({
    required this.homeScore,
    required this.awayScore,
    required this.possessionHome,
    required this.shotsHome,
    required this.shotsAway,
    required this.shotsOnTargetHome,
    required this.shotsOnTargetAway,
  });

  final int homeScore;
  final int awayScore;
  final int possessionHome;
  final int shotsHome;
  final int shotsAway;
  final int shotsOnTargetHome;
  final int shotsOnTargetAway;
}

class _ResultsView extends StatelessWidget {
  const _ResultsView({
    required this.resultsFuture,
    required this.onReset,
    required this.summary,
  });

  final Future<List<SimulationResultModel>> resultsFuture;
  final VoidCallback onReset;
  final MatchSummary summary;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<SimulationResultModel>>(
      key: const ValueKey('results-view'),
      future: resultsFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _ErrorState(message: snapshot.error.toString());
        }

        final isLoading = snapshot.connectionState == ConnectionState.waiting;
        final results = snapshot.data ?? [];
        if (!isLoading && results.isEmpty) {
          return const _ErrorState(message: 'No results were returned.');
        }

        final injured = results.where((result) {
          final status = result.status.toUpperCase();
          if (status.contains('INJURED')) {
            return true;
          }
          final hasType = (result.injuryType ?? '').trim().isNotEmpty;
          final recoveryDays = result.recoveryDays ?? 0;
          return hasType && recoveryDays > 0;
        }).toList();

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemBuilder: (context, index) {
            if (index == 0) {
              return _ResultsHeader(
                onReset: onReset,
                summary: summary,
                injuredPlayers: injured,
                isLoading: isLoading,
              );
            }
            if (isLoading && index == 1) {
              return const _LoadingResultsCard();
            }
            final offset = isLoading ? 2 : 1;
            return _ResultCard(result: results[index - offset]);
          },
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemCount: results.length + 1 + (isLoading ? 1 : 0),
        );
      },
    );
  }
}

class _ResultsHeader extends StatelessWidget {
  const _ResultsHeader({
    required this.onReset,
    required this.summary,
    required this.injuredPlayers,
    required this.isLoading,
  });

  final VoidCallback onReset;
  final MatchSummary summary;
  final List<SimulationResultModel> injuredPlayers;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.cardBorder),
          ),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Match results + medical updates',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
              ),
              TextButton.icon(
                onPressed: onReset,
                icon: Icon(Icons.refresh, size: 18),
                label: Text('New match'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.accentBlue,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _MatchStatsCard(summary: summary),
        const SizedBox(height: 12),
        _InjuredPlayersCard(players: injuredPlayers, isLoading: isLoading),
      ],
    );
  }
}

class _MatchStatsCard extends StatelessWidget {
  const _MatchStatsCard({required this.summary});

  final MatchSummary summary;

  @override
  Widget build(BuildContext context) {
    final possessionAway = 100 - summary.possessionHome;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Match stats',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
          const SizedBox(height: 12),
          _StatRow(
            label: 'Score',
            value: '${summary.homeScore} - ${summary.awayScore}',
          ),
          const SizedBox(height: 8),
          _StatRow(
            label: 'Possession',
            value: '${summary.possessionHome}% / $possessionAway%',
          ),
          const SizedBox(height: 8),
          _StatRow(
            label: 'Shots',
            value: '${summary.shotsHome} / ${summary.shotsAway}',
          ),
          const SizedBox(height: 8),
          _StatRow(
            label: 'Shots on target',
            value:
                '${summary.shotsOnTargetHome} / ${summary.shotsOnTargetAway}',
          ),
        ],
      ),
    );
  }
}

class _InjuredPlayersCard extends StatelessWidget {
  const _InjuredPlayersCard({required this.players, required this.isLoading});

  final List<SimulationResultModel> players;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Injured players (match squad)',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
          const SizedBox(height: 12),
          if (players.isEmpty && isLoading)
            Text(
              'Medical analysis running...'
              ' This may take a minute.',
              style: TextStyle(color: AppTheme.textSecondary),
            )
          else if (players.isEmpty)
            Text(
              'No injuries recorded for this match.',
              style: TextStyle(color: AppTheme.textSecondary),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final player in players)
                  _InjuryChip(
                    name: player.name,
                    detail: player.injuryType ?? player.severity,
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _LoadingResultsCard extends StatelessWidget {
  const _LoadingResultsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppTheme.accentBlue,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Calculating medical results and injuries...'
              ' Please wait.',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _InjuryChip extends StatelessWidget {
  const _InjuryChip({required this.name, this.detail});

  final String name;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.danger.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.danger.withOpacity(0.35)),
      ),
      child: Text(
        detail == null || detail!.trim().isEmpty
            ? name
            : '$name • ${detail!.trim()}',
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label, style: TextStyle(color: AppTheme.textSecondary)),
        const Spacer(),
        Text(value, style: TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result});

  final SimulationResultModel result;

  Color _statusColor() {
    switch (result.status.toUpperCase()) {
      case 'INJURED':
        return AppTheme.danger;
      case 'WARNING':
        return AppTheme.warning;
      default:
        return AppTheme.success;
    }
  }

  String _playedLabel() {
    final playedAt = result.playedAt;
    if (playedAt == null) {
      return 'Played match';
    }

    final diff = DateTime.now().difference(playedAt);
    if (diff.inMinutes < 60) {
      return 'Played ${diff.inMinutes}m ago';
    }
    if (diff.inHours < 24) {
      return 'Played ${diff.inHours}h ago';
    }
    return 'Played ${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final probability = result.injuryProbability.clamp(0.0, 1.0).toDouble();
    final statusColor = _statusColor();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.cardBorder),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.2),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  result.name,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              if (result.playedMatch)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _PlayedBadge(label: _playedLabel()),
                ),
              _StatusBadge(label: result.status, color: statusColor),
            ],
          ),
          const SizedBox(height: 12),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: probability),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: LinearProgressIndicator(
                  value: value,
                  minHeight: 10,
                  backgroundColor: AppTheme.surfaceAlt,
                  color: statusColor,
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Injury probability ${(probability * 100).toStringAsFixed(0)}%',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
              const Spacer(),
              Text(
                'Load ${result.load.toStringAsFixed(0)}',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _InfoChip(
                label: 'Fatigue',
                value: result.fatigue.toStringAsFixed(0),
              ),
              _InfoChip(label: 'Severity', value: result.severity ?? 'Mild'),
              _InfoChip(
                label: 'Recovery',
                value: result.recoveryDays != null
                    ? '${result.recoveryDays} days'
                    : 'N/A',
              ),
              if ((result.injuryType ?? '').isNotEmpty)
                _InfoChip(label: 'Type', value: result.injuryType!),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: color,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label ',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            ),
            TextSpan(
              text: value,
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.danger.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.danger.withOpacity(0.3)),
      ),
      child: Text(
        message,
        style: TextStyle(color: AppTheme.danger, fontSize: 12),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: AppTheme.danger, size: 36),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
