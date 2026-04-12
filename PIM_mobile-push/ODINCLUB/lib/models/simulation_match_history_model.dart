class SimulationMatchHistoryItem {
  const SimulationMatchHistoryItem({
    required this.matchId,
    required this.endedAt,
    required this.injuredCount,
    required this.warningCount,
    required this.safeCount,
    required this.injuredPlayers,
    required this.stats,
    required this.results,
  });

  final String matchId;
  final DateTime endedAt;
  final int injuredCount;
  final int warningCount;
  final int safeCount;
  final List<SimulationInjuredPlayer> injuredPlayers;
  final SimulationMatchStats stats;
  final List<SimulationPlayerResult> results;

  factory SimulationMatchHistoryItem.fromJson(Map<String, dynamic> json) {
    final injuredJson = json['injuredPlayers'];
    final statsJson = json['stats'];
    final resultsJson = json['results'];
    return SimulationMatchHistoryItem(
      matchId: (json['matchId'] ?? '').toString(),
      endedAt:
          DateTime.tryParse((json['endedAt'] ?? '').toString()) ??
          DateTime.now(),
      injuredCount: _simIntFrom(json['injuredCount']),
      warningCount: _simIntFrom(json['warningCount']),
      safeCount: _simIntFrom(json['safeCount']),
      injuredPlayers: injuredJson is List
          ? injuredJson
                .map(
                  (item) => SimulationInjuredPlayer.fromJson(
                    item as Map<String, dynamic>,
                  ),
                )
                .toList()
          : const [],
      stats: statsJson is Map<String, dynamic>
          ? SimulationMatchStats.fromJson(statsJson)
          : const SimulationMatchStats(),
      results: resultsJson is List
          ? resultsJson
                .map(
                  (item) => SimulationPlayerResult.fromJson(
                    item as Map<String, dynamic>,
                  ),
                )
                .toList()
          : const [],
    );
  }
}

class SimulationMatchStats {
  const SimulationMatchStats({
    this.homeScore = 0,
    this.awayScore = 0,
    this.possessionHome = 50,
    this.shotsHome = 0,
    this.shotsAway = 0,
    this.shotsOnTargetHome = 0,
    this.shotsOnTargetAway = 0,
  });

  final int homeScore;
  final int awayScore;
  final int possessionHome;
  final int shotsHome;
  final int shotsAway;
  final int shotsOnTargetHome;
  final int shotsOnTargetAway;

  factory SimulationMatchStats.fromJson(Map<String, dynamic> json) {
    return SimulationMatchStats(
      homeScore: _simIntFrom(json['homeScore']),
      awayScore: _simIntFrom(json['awayScore']),
      possessionHome: _simIntFrom(json['possessionHome']),
      shotsHome: _simIntFrom(json['shotsHome']),
      shotsAway: _simIntFrom(json['shotsAway']),
      shotsOnTargetHome: _simIntFrom(json['shotsOnTargetHome']),
      shotsOnTargetAway: _simIntFrom(json['shotsOnTargetAway']),
    );
  }
}

class SimulationPlayerResult {
  const SimulationPlayerResult({
    required this.playerId,
    required this.name,
    required this.fatigue,
    required this.load,
    required this.injuryProbability,
    required this.status,
    required this.injuryType,
    required this.recoveryDays,
    required this.severity,
  });

  final String playerId;
  final String name;
  final double fatigue;
  final double load;
  final double injuryProbability;
  final String status;
  final String? injuryType;
  final int? recoveryDays;
  final String? severity;

  factory SimulationPlayerResult.fromJson(Map<String, dynamic> json) {
    return SimulationPlayerResult(
      playerId: (json['playerId'] ?? '').toString(),
      name: (json['name'] ?? 'Unknown').toString(),
      fatigue: _simDoubleFrom(json['fatigue']),
      load: _simDoubleFrom(json['load']),
      injuryProbability: _simDoubleFrom(json['injuryProbability']),
      status: (json['status'] ?? 'SAFE').toString(),
      injuryType: json['injuryType']?.toString(),
      recoveryDays: _simIntFrom(json['recoveryDays']),
      severity: json['severity']?.toString(),
    );
  }
}

class SimulationInjuredPlayer {
  const SimulationInjuredPlayer({
    required this.playerId,
    required this.name,
    required this.injuryType,
    required this.recoveryDays,
    required this.severity,
    required this.injuryProbability,
  });

  final String playerId;
  final String name;
  final String? injuryType;
  final int? recoveryDays;
  final String? severity;
  final double injuryProbability;

  factory SimulationInjuredPlayer.fromJson(Map<String, dynamic> json) {
    return SimulationInjuredPlayer(
      playerId: (json['playerId'] ?? '').toString(),
      name: (json['name'] ?? 'Unknown').toString(),
      injuryType: json['injuryType']?.toString(),
      recoveryDays: _simNullableIntFrom(json['recoveryDays']),
      severity: json['severity']?.toString(),
      injuryProbability: _simDoubleFrom(json['injuryProbability']),
    );
  }
}

int _simIntFrom(dynamic value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

int? _simNullableIntFrom(dynamic value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '');
}

double _simDoubleFrom(dynamic value) {
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value?.toString() ?? '') ?? 0;
}
