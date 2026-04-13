class PlayerMetrics {
  final String playerId;
  final String playerName;
  final String position;
  final String? matchDate;

  // Training load
  final double? acwr;
  final double? trainingLoadKm;

  // Biometrics
  final int? hrvScore;
  final double? sleepHours;
  final int? sleepQuality;

  // Physical
  final int? muscularPainLevel;
  final int? fatigueLevel;

  // Medical
  final String? injuryHistory;
  final String? activeInjuryZones;
  final int? daysSinceLastInjury;

  // Recent form
  final double? lastMatchRating;
  final int? goalsLast5;
  final int? minutesLast5;

  final int? daysToMatch;

  const PlayerMetrics({
    required this.playerId,
    required this.playerName,
    required this.position,
    this.matchDate,
    this.acwr,
    this.trainingLoadKm,
    this.hrvScore,
    this.sleepHours,
    this.sleepQuality,
    this.muscularPainLevel,
    this.fatigueLevel,
    this.injuryHistory,
    this.activeInjuryZones,
    this.daysSinceLastInjury,
    this.lastMatchRating,
    this.goalsLast5,
    this.minutesLast5,
    this.daysToMatch,
  });

  Map<String, dynamic> toJson() => {
    'playerId': playerId,
    'playerName': playerName,
    'position': position,
    if (matchDate != null) 'matchDate': matchDate,
    if (acwr != null) 'acwr': acwr,
    if (trainingLoadKm != null) 'trainingLoadKm': trainingLoadKm,
    if (hrvScore != null) 'hrvScore': hrvScore,
    if (sleepHours != null) 'sleepHours': sleepHours,
    if (sleepQuality != null) 'sleepQuality': sleepQuality,
    if (muscularPainLevel != null) 'muscularPainLevel': muscularPainLevel,
    if (fatigueLevel != null) 'fatigueLevel': fatigueLevel,
    if (injuryHistory != null) 'injuryHistory': injuryHistory,
    if (activeInjuryZones != null) 'activeInjuryZones': activeInjuryZones,
    if (daysSinceLastInjury != null) 'daysSinceLastInjury': daysSinceLastInjury,
    if (lastMatchRating != null) 'lastMatchRating': lastMatchRating,
    if (goalsLast5 != null) 'goalsLast5': goalsLast5,
    if (minutesLast5 != null) 'minutesLast5': minutesLast5,
    if (daysToMatch != null) 'daysToMatch': daysToMatch,
  };
}
