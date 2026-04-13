class PlayerValueRequest {
  PlayerValueRequest({
    required this.age,
    required this.minutesPlayed,
    required this.goals,
    required this.assists,
    required this.injuriesLastSeason,
    required this.currentMarketValue,
  });

  final int age;
  final int minutesPlayed;
  final int goals;
  final int assists;
  final int injuriesLastSeason;
  final double currentMarketValue;

  Map<String, dynamic> toJson() => {
        'age': age,
        'minutes_played': minutesPlayed,
        'goals': goals,
        'assists': assists,
        'injuries_last_season': injuriesLastSeason,
        'current_market_value': currentMarketValue,
      };
}

class PlayerValueResponse {
  PlayerValueResponse({
    required this.predictedValue,
    required this.growthPercent,
    required this.trend,
    required this.confidence,
    required this.explanation,
    required this.chart,
    required this.nextSeasonProjection,
  });

  final double predictedValue;
  final double growthPercent;
  final String trend;
  final double confidence;
  final String explanation;
  final List<Map<String, dynamic>> chart;
  final Map<String, dynamic> nextSeasonProjection;

  factory PlayerValueResponse.fromJson(Map<String, dynamic> json) {
    return PlayerValueResponse(
      predictedValue: (json['predicted_value'] as num).toDouble(),
      growthPercent: (json['growth_percent'] as num).toDouble(),
      trend: (json['trend'] as String),
      confidence: (json['confidence'] as num).toDouble(),
      explanation: (json['explanation'] as String),
      chart: (json['chart'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
      nextSeasonProjection:
          Map<String, dynamic>.from(json['next_season_projection'] as Map),
    );
  }
}
