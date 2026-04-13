import 'player.dart';

class TopPlayer {
  final String eventPlayerId;
  final Player player;
  final double score;
  final int rank;

  TopPlayer({
    required this.eventPlayerId,
    required this.player,
    required this.score,
    required this.rank,
  });

  factory TopPlayer.fromJson(Map<String, dynamic> json) {
    return TopPlayer(
      eventPlayerId: json['eventPlayerId'] ?? '', // Handle potential null if backend isn't updated yet
      player: json['player'] != null 
          ? Player.fromJson(json['player'])
          : (json['playerId'] is String
              ? Player(
                  id: json['playerId'],
                  firstName: '',
                  lastName: '',
                  dateOfBirth: DateTime.now(),
                  position: '',
                  strongFoot: 'Right',
                )
              : Player.fromJson(json['playerId'])),
      score: (json['score'] ?? 0).toDouble(),
      rank: json['rank'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'eventPlayerId': eventPlayerId,
      'playerId': player.id, // Keep backward compat or simplify
      'player': player.toJson(),
      'score': score,
      'rank': rank,
    };
  }
}

// Ranked Player Model
class RankedPlayer {
  final String eventPlayerId;
  final Player player;
  final double score;
  final int rank;
  final double scoreTrend;

  RankedPlayer({
    required this.eventPlayerId,
    required this.player,
    required this.score,
    required this.rank,
    this.scoreTrend = 0,
  });

  factory RankedPlayer.fromJson(Map<String, dynamic> json) {
    return RankedPlayer(
      eventPlayerId: json['eventPlayerId'] ?? '',
      player: json['player'] != null
          ? Player.fromJson(json['player'])
          : (json['playerId'] is String
              ? Player(
                  id: json['playerId'],
                  firstName: '',
                  lastName: '',
                  dateOfBirth: DateTime.now(),
                  position: '',
                  strongFoot: 'Right',
                )
              : Player.fromJson(json['playerId'])),
      score: (json['score'] ?? 0).toDouble(),
      rank: json['rank'] ?? 0,
      scoreTrend: (json['scoreTrend'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'eventPlayerId': eventPlayerId,
      'playerId': player.id,
      'player': player.toJson(),
      'score': score,
      'rank': rank,
    };
  }
}

// Category Stat Model
class CategoryStat {
  final double avg;
  final double min;
  final double max;

  CategoryStat({
    required this.avg,
    required this.min,
    required this.max,
  });

  factory CategoryStat.fromJson(Map<String, dynamic> json) {
    return CategoryStat(
      avg: (json['avg'] ?? 0).toDouble(),
      min: (json['min'] ?? 0).toDouble(),
      max: (json['max'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'avg': avg,
      'min': min,
      'max': max,
    };
  }
}

// Report Statistics Model
class ReportStatistics {
  final double averageScore;
  final double medianScore;
  final double standardDeviation;
  final double minScore;
  final double maxScore;
  final Map<String, CategoryStat> byCategory;

  ReportStatistics({
    required this.averageScore,
    required this.medianScore,
    required this.standardDeviation,
    required this.minScore,
    required this.maxScore,
    this.byCategory = const {},
  });

  factory ReportStatistics.fromJson(Map<String, dynamic> json) {
    Map<String, CategoryStat> categories = {};
    if (json['byCategory'] != null && json['byCategory'] is Map) {
      final categoryMap = json['byCategory'] as Map<String, dynamic>;
      categoryMap.forEach((key, value) {
        categories[key] = CategoryStat.fromJson(value);
      });
    }

    return ReportStatistics(
      averageScore: (json['averageScore'] ?? 0).toDouble(),
      medianScore: (json['medianScore'] ?? 0).toDouble(),
      standardDeviation: (json['standardDeviation'] ?? 0).toDouble(),
      minScore: (json['minScore'] ?? 0).toDouble(),
      maxScore: (json['maxScore'] ?? 0).toDouble(),
      byCategory: categories,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'averageScore': averageScore,
      'medianScore': medianScore,
      'standardDeviation': standardDeviation,
      'minScore': minScore,
      'maxScore': maxScore,
      'byCategory': byCategory.map((key, value) => MapEntry(key, value.toJson())),
    };
  }
}

// Event Report Model
class EventReport {
  final String id;
  final String eventId;
  final int totalPlayers;
  final int completedTests;
  final double averageScore;
  final List<TopPlayer> topPlayers;
  final List<RankedPlayer> ranking;
  final ReportStatistics statistics;
  final DateTime generatedAt;

  EventReport({
    required this.id,
    required this.eventId,
    required this.totalPlayers,
    required this.completedTests,
    required this.averageScore,
    required this.topPlayers,
    required this.ranking,
    required this.statistics,
    required this.generatedAt,
  });

  factory EventReport.fromJson(Map<String, dynamic> json) {
    return EventReport(
      id: json['_id'] ?? json['id'],
      eventId: json['eventId'],
      totalPlayers: json['totalPlayers'],
      completedTests: json['completedTests'],
      averageScore: json['averageScore'].toDouble(),
      topPlayers: (json['topPlayers'] as List<dynamic>)
          .map((tp) => TopPlayer.fromJson(tp))
          .toList(),
      ranking: (json['ranking'] as List<dynamic>)
          .map((rp) => RankedPlayer.fromJson(rp))
          .toList(),
      statistics: json['statistics'] != null
          ? ReportStatistics.fromJson(json['statistics'])
          : ReportStatistics(
              averageScore: json['averageScore'].toDouble(),
              medianScore: 0,
              standardDeviation: 0,
              minScore: 0,
              maxScore: 0,
            ),
      generatedAt: json['generatedAt'] != null
          ? DateTime.parse(json['generatedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'eventId': eventId,
      'totalPlayers': totalPlayers,
      'completedTests': completedTests,
      'averageScore': averageScore,
      'topPlayers': topPlayers.map((tp) => tp.toJson()).toList(),
      'ranking': ranking.map((rp) => rp.toJson()).toList(),
      'statistics': statistics.toJson(),
    };
  }

  List<RankedPlayer> get top3Players => ranking.take(3).toList();
}
