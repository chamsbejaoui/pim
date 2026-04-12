import 'event_player.dart';

// Test Score Model (for player report)
class TestScore {
  final String testTypeId;
  final String testName;
  final double score;
  final String category;

  TestScore({
    required this.testTypeId,
    required this.testName,
    required this.score,
    required this.category,
  });

  factory TestScore.fromJson(Map<String, dynamic> json) {
    return TestScore(
      testTypeId: json['testTypeId'],
      testName: json['testName'],
      score: json['score'].toDouble(),
      category: json['category'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'testTypeId': testTypeId,
      'testName': testName,
      'score': score,
      'category': category,
    };
  }
}

// Player Report Model
class PlayerReport {
  final String id;
  final dynamic eventPlayer; // Can be ID string or EventPlayer object
  final double overallScore;
  final int rank;
  final int totalPlayers;
  final double eventAverage;
  final double deviation;
  final double scoreTrend;
  final List<TestScore> testScores;
  final List<String> strengths;
  final List<String> weaknesses;
  final String recommendation;
  final bool isTopPlayer;
  final DateTime generatedAt;

  PlayerReport({
    required this.id,
    required this.eventPlayer,
    required this.overallScore,
    required this.rank,
    required this.totalPlayers,
    required this.eventAverage,
    required this.deviation,
    required this.scoreTrend,
    required this.testScores,
    required this.strengths,
    required this.weaknesses,
    required this.recommendation,
    required this.isTopPlayer,
    required this.generatedAt,
  });

  factory PlayerReport.fromJson(Map<String, dynamic> json) {
    return PlayerReport(
      id: json['_id'] ?? json['id'],
      eventPlayer: json['eventPlayerId'] is String
        ? json['eventPlayerId']
        : EventPlayer.fromJson(json['eventPlayerId']),
      overallScore: json['overallScore'].toDouble(),
      rank: json['rank'],
      totalPlayers: json['totalPlayers'],
      eventAverage: json['eventAverage'].toDouble(),
      deviation: json['deviation'].toDouble(),
      scoreTrend: (json['scoreTrend'] ?? 0).toDouble(),
      testScores: (json['testScores'] as List<dynamic>)
          .map((ts) => TestScore.fromJson(ts))
          .toList(),
      strengths: List<String>.from(json['strengths'] ?? []),
      weaknesses: List<String>.from(json['weaknesses'] ?? []),
      recommendation: json['recommendation'] ?? '',
      isTopPlayer: json['isTopPlayer'] ?? false,
      generatedAt: json['generatedAt'] != null
          ? DateTime.parse(json['generatedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'eventPlayerId': eventPlayer is String ? eventPlayer : eventPlayer.id,
      'overallScore': overallScore,
      'rank': rank,
      'totalPlayers': totalPlayers,
      'eventAverage': eventAverage,
      'deviation': deviation,
      'scoreTrend': scoreTrend,
      'testScores': testScores.map((ts) => ts.toJson()).toList(),
      'strengths': strengths,
      'weaknesses': weaknesses,
      'recommendation': recommendation,
      'isTopPlayer': isTopPlayer,
    };
  }

  String get performanceLevel {
    if (overallScore >= 90) return 'Excellent';
    if (overallScore >= 75) return 'Très bon';
    if (overallScore >= 60) return 'Bon';
    if (overallScore >= 50) return 'Moyen';
    return 'À améliorer';
  }

  String get rankingSuffix {
    if (rank == 1) return 'er';
    return 'ème';
  }

  String get rankLabel => '$rank$rankingSuffix / $totalPlayers';

  double get deviationPercent {
    if (eventAverage == 0) return 0;
    return (deviation / eventAverage) * 100;
  }

  bool get aboveAverage => deviation > 0;
  bool get belowAverage => deviation < 0;
}
