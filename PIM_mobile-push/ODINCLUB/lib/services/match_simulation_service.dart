import 'dart:async';
import 'dart:math' as math;

import '../models/alert_model.dart';
import '../models/medical_result_model.dart';
import '../models/player_model.dart';
import '../services/alert_service.dart';
import '../services/medical_service.dart';

class MatchSimulationService {
  MatchSimulationService({
    MedicalService? medicalService,
    AlertService? alertService,
    math.Random? random,
  }) : _medicalService = medicalService ?? MedicalService(),
       _alertService = alertService ?? AlertService.instance,
       _random = random ?? math.Random();

  final MedicalService _medicalService;
  final AlertService _alertService;
  final math.Random _random;

  final Map<String, _PlayerMatchState> _states = {};
  final List<String> _playerOrder = [];
  static const int _maxChecksPerTick = 2;
  Timer? _tickTimer;
  bool _running = false;
  bool _inFlight = false;
  int _cursor = 0;
  final Map<String, AlertModel> _latestByPlayer = {};

  AlertModel? get mostSevereAlert {
    if (_latestByPlayer.isEmpty) {
      return null;
    }
    AlertModel? best;
    for (final alert in _latestByPlayer.values) {
      if (best == null) {
        best = alert;
        continue;
      }
      if (alert.fatigue > best.fatigue) {
        best = alert;
        continue;
      }
      if (alert.fatigue == best.fatigue) {
        final bestRank = _statusRank(best.status);
        final alertRank = _statusRank(alert.status);
        if (alertRank > bestRank) {
          best = alert;
          continue;
        }
        if (alertRank == bestRank && alert.risk >= best.risk) {
          best = alert;
        }
      }
    }
    return best;
  }

  void start(List<PlayerModel> players) {
    stop();
    _initializeStates(players);
    _running = true;
    _scheduleNextTick();
  }

  Future<void> warmup(List<PlayerModel> players) async {
    stop();
    _initializeStates(players);
    final snapshot = List<_PlayerMatchState>.from(_states.values);
    for (final state in snapshot) {
      await _analyzeState(state, forceSilent: true);
    }
  }

  void stop() {
    _running = false;
    _tickTimer?.cancel();
    _tickTimer = null;
    _inFlight = false;
  }

  void dispose() {
    stop();
  }

  void _scheduleNextTick() {
    if (!_running) {
      return;
    }
    final delay = Duration(milliseconds: 2000 + _random.nextInt(1000));
    _tickTimer = Timer(delay, _tick);
  }

  void _initializeStates(List<PlayerModel> players) {
    _states.clear();
    _playerOrder
      ..clear()
      ..addAll(players.map((player) => player.id));
    _cursor = 0;

    for (final player in players) {
      _states[player.id] = _PlayerMatchState(
        player: player,
        fatigue: (player.lastMatchFatigue ?? 30).toDouble(),
        load: (player.lastMatchLoad ?? 30).toDouble(),
        minutes: 0,
      );
    }
  }

  Future<void> _tick() async {
    if (!_running || _inFlight) {
      return;
    }

    if (_states.isEmpty || _playerOrder.isEmpty) {
      _scheduleNextTick();
      return;
    }

    _inFlight = true;

    for (final state in _states.values) {
      _updateStats(state);
    }

    _emitHeartbeat();

    final futures = <Future<void>>[];
    for (var i = 0; i < _maxChecksPerTick; i += 1) {
      final state = _nextState();
      if (state == null) {
        break;
      }
      futures.add(_analyzeState(state));
    }

    await Future.wait(futures);
    _inFlight = false;

    if (_running) {
      _scheduleNextTick();
    }
  }

  void _emitHeartbeat() {
    final current = mostSevereAlert;
    if (current == null) {
      return;
    }
    final state = _states[current.playerId];
    if (state == null) {
      return;
    }
    final refreshed = AlertModel(
      playerId: current.playerId,
      playerName: current.playerName,
      risk: current.risk,
      fatigue: state.fatigue,
      load: state.load,
      minutes: state.minutes,
      injuryType: current.injuryType,
      severity: current.severity,
      recoveryDays: current.recoveryDays,
      status: current.status,
      decision: current.decision,
      reasons: current.reasons,
      notify: false,
      createdAt: DateTime.now(),
    );
    _alertService.emit(refreshed);
  }

  _PlayerMatchState? _nextState() {
    if (_playerOrder.isEmpty) {
      return null;
    }

    for (var i = 0; i < _playerOrder.length; i += 1) {
      final id = _playerOrder[_cursor % _playerOrder.length];
      _cursor = (_cursor + 1) % _playerOrder.length;
      final state = _states[id];
      if (state != null) {
        return state;
      }
    }
    return null;
  }

  void _updateStats(_PlayerMatchState state) {
    state.fatigue = _clamp(state.fatigue + _randomInRange(3, 8), 0, 100);
    state.load = _clamp(state.load + _randomInRange(2, 5), 0, 100);
    state.minutes = _clampInt(state.minutes + 2, 0, 90);
  }

  Future<void> _analyzeState(
    _PlayerMatchState state, {
    bool forceSilent = false,
  }) async {
    MedicalResultModel result;
    try {
      result = await _medicalService.analyze(
        playerId: state.player.id,
        fatigue: state.fatigue,
        minutes: state.minutes.toDouble(),
        load: state.load,
      );
    } catch (_) {
      return;
    }

    final risk = result.risk > 0 ? result.risk : result.injuryProbability;
    final status = _statusFrom(result.status, risk);
    final decision = _decisionFrom(result.decision, status);

    final now = DateTime.now();
    final lastRisk = state.lastRisk ?? 0.0;
    final riskJumped = (risk - lastRisk) > 0.1;
    final statusChanged = state.lastStatus != status;
    final cooldownActive =
        state.lastAlertAt != null &&
        now.difference(state.lastAlertAt!).inSeconds < 5;

    state.lastRisk = risk;
    state.lastStatus = status;

    final shouldNotify =
        status != AlertStatus.safe &&
        (statusChanged || riskJumped) &&
        !cooldownActive &&
        !(state.lastAlertStatus == status && !riskJumped) &&
        !forceSilent;

    final reasons = result.reasons.isNotEmpty
        ? result.reasons
        : _fallbackReasons(state, result.warning);

    final alert = AlertModel(
      playerId: state.player.id,
      playerName: state.player.name,
      risk: risk,
      fatigue: state.fatigue,
      load: state.load,
      minutes: state.minutes,
      injuryType: result.injuryType,
      severity: result.severity,
      recoveryDays: result.recoveryDays,
      status: status,
      decision: decision,
      reasons: reasons,
      notify: shouldNotify,
      createdAt: now,
    );

    _latestByPlayer[state.player.id] = alert;

    if (shouldNotify) {
      state.lastAlertStatus = status;
      state.lastAlertAt = now;
    }
    _alertService.emit(alert);
  }

  int _statusRank(AlertStatus status) {
    switch (status) {
      case AlertStatus.injured:
        return 2;
      case AlertStatus.warning:
        return 1;
      case AlertStatus.safe:
        return 0;
    }
  }

  AlertStatus _statusFrom(String status, double risk) {
    switch (status.toUpperCase()) {
      case 'INJURED':
        return AlertStatus.injured;
      case 'WARNING':
        return AlertStatus.warning;
      case 'SAFE':
        return AlertStatus.safe;
    }

    if (risk < 0.25) {
      return AlertStatus.safe;
    }
    if (risk <= 0.4) {
      return AlertStatus.warning;
    }
    return AlertStatus.injured;
  }

  AlertDecision _decisionFrom(String decision, AlertStatus status) {
    switch (decision.toUpperCase()) {
      case 'SUBSTITUTE':
        return AlertDecision.substitute;
      case 'LIMIT':
        return AlertDecision.limit;
      case 'PLAY':
        return AlertDecision.play;
    }

    switch (status) {
      case AlertStatus.injured:
        return AlertDecision.substitute;
      case AlertStatus.warning:
        return AlertDecision.limit;
      case AlertStatus.safe:
        return AlertDecision.play;
    }
  }

  List<String> _fallbackReasons(_PlayerMatchState state, String warning) {
    final reasons = <String>[];
    if (state.fatigue >= 70) {
      reasons.add('High fatigue');
    }
    if (state.load >= 70) {
      reasons.add('High load');
    }
    if (state.minutes >= 75) {
      reasons.add('High minutes');
    }
    if (reasons.isEmpty && warning.trim().isNotEmpty) {
      reasons.add(warning.trim());
    }
    if (reasons.isEmpty) {
      reasons.add('Elevated injury risk');
    }
    return reasons;
  }

  double _randomInRange(int min, int max) {
    return (min + _random.nextInt(max - min + 1)).toDouble();
  }

  double _clamp(double value, double min, double max) {
    if (value < min) {
      return min;
    }
    if (value > max) {
      return max;
    }
    return value;
  }

  int _clampInt(int value, int min, int max) {
    if (value < min) {
      return min;
    }
    if (value > max) {
      return max;
    }
    return value;
  }
}

class _PlayerMatchState {
  _PlayerMatchState({
    required this.player,
    required this.fatigue,
    required this.load,
    required this.minutes,
  });

  final PlayerModel player;
  double fatigue;
  double load;
  int minutes;
  double? lastRisk;
  AlertStatus? lastStatus;
  AlertStatus? lastAlertStatus;
  DateTime? lastAlertAt;
}
