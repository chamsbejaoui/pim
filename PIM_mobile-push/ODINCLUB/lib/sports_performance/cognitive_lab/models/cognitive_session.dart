class TacticalMemoryMetrics {
  final int avgDistanceError;
  final int ballDistanceError;
  final int timeMs;

  TacticalMemoryMetrics({
    required this.avgDistanceError,
    required this.ballDistanceError,
    required this.timeMs,
  });

  Map<String, dynamic> toJson() => {
    'avgDistanceError': avgDistanceError,
    'ballDistanceError': ballDistanceError,
    'timeMs': timeMs,
  };
}

class CognitiveScores {
  final int? reactionScore;
  final int? focusScore;
  final int? memoryScore;
  final int? mentalScore;
  final int? decisionScore;
  final int? wellnessScore;
  final int? tacticalIqScore;
  final String? tacticalProfile;
  final String? trainingReadiness;

  CognitiveScores({
    this.reactionScore,
    this.focusScore,
    this.memoryScore,
    this.mentalScore,
    this.decisionScore,
    this.wellnessScore,
    this.tacticalIqScore,
    this.tacticalProfile,
    this.trainingReadiness,
  });

  factory CognitiveScores.fromJson(Map<String, dynamic> json) {
    return CognitiveScores(
      reactionScore: (json['reactionScore'] as num?)?.toInt(),
      focusScore: (json['focusScore'] as num?)?.toInt(),
      memoryScore: (json['memoryScore'] as num?)?.toInt(),
      mentalScore: (json['mentalScore'] as num?)?.toInt(),
      decisionScore: (json['decisionScore'] as num?)?.toInt(),
      wellnessScore: (json['wellnessScore'] as num?)?.toInt(),
      tacticalIqScore: (json['tacticalIqScore'] as num?)?.toInt(),
      tacticalProfile: json['tacticalProfile'],
      trainingReadiness: json['trainingReadiness'],
    );
  }
}

class ReactionMetrics {
  final int avgMs;
  final int bestMs;
  final int worstMs;
  final int accuracy;

  ReactionMetrics({
    required this.avgMs,
    required this.bestMs,
    required this.worstMs,
    required this.accuracy,
  });

  Map<String, dynamic> toJson() => {
    'avgMs': avgMs,
    'bestMs': bestMs,
    'worstMs': worstMs,
    'accuracy': accuracy,
  };
}

class FocusMetrics {
  final int completionTime;
  final int errors;

  FocusMetrics({
    required this.completionTime,
    required this.errors,
  });

  Map<String, dynamic> toJson() => {
    'completionTime': completionTime,
    'errors': errors,
  };
}

class MemoryMetrics {
  final int correctSequences;
  final int failures;
  final int maxLevel;

  MemoryMetrics({
    required this.correctSequences,
    required this.failures,
    required this.maxLevel,
  });

  Map<String, dynamic> toJson() => {
    'correctSequences': correctSequences,
    'failures': failures,
    'maxLevel': maxLevel,
  };
}

class CognitiveSession {
  final String id;
  final String playerId;
  final DateTime date;
  
  final CognitiveScores? scores;
  final String? aiStatus;
  final String? riskLevel;
  final String? aiRecommendationText;
  final String? trainingSuggestion;
  final String? playerName;
  final String? playerPosition;

  CognitiveSession({
    required this.id,
    required this.playerId,
    required this.date,
    this.scores,
    this.aiStatus,
    this.riskLevel,
    this.aiRecommendationText,
    this.trainingSuggestion,
    this.playerName,
    this.playerPosition,
  });

  factory CognitiveSession.fromJson(Map<String, dynamic> json) {
    // Si le JSON contient un objet playerInfo imbriqué (cas du dashboard)
    final playerInfo = json['playerInfo'] as Map<String, dynamic>?;
    final nameFromInfo = playerInfo != null 
        ? "${playerInfo['firstName']} ${playerInfo['lastName']}" 
        : null;
    final posFromInfo = playerInfo?['position'];

    return CognitiveSession(
      id: json['_id'] ?? 'new', // Fallback id 'new' pour les profils sans sessions
      playerId: json['playerId'] ?? '',
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      scores: json['scores'] != null ? CognitiveScores.fromJson(json['scores']) : null,
      aiStatus: json['aiStatus'],
      riskLevel: json['riskLevel'],
      aiRecommendationText: json['aiRecommendationText'],
      trainingSuggestion: json['trainingSuggestion'],
      playerName: nameFromInfo ?? json['playerName'], // Fallback sur playerName direct (cas du squad overview)
      playerPosition: posFromInfo ?? json['playerPosition'],
    );
  }
}
