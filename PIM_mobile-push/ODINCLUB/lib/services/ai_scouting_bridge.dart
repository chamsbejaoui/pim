import '../sports_performance/models/player.dart' as sp;
import '../sports_performance/models/player_report.dart';
import '../sports_performance/models/event_player.dart';
import 'ai_api_service.dart';
import '../models/ai_player.dart';

/// Maps Sports Performance test results to AI Scouting 7 metrics
/// and sends the player to the AI module for evaluation.
class AiScoutingBridge {
  /// Known test name patterns mapped to AI metric keys.
  /// The SP module uses dynamic TestTypes with free-text names,
  /// so we match by keyword.
  static const _speedKeywords = [
    'speed', 'vitesse', 'sprint', 'acceleration', 'accélération', '30m', '40m',
  ];
  static const _enduranceKeywords = [
    'endurance', 'vo2', 'stamina', 'cooper', 'yoyo', 'yo-yo', 'beep',
    'résistance', 'resistance', 'cardio',
  ];
  static const _distanceKeywords = [
    'distance', 'covered', 'parcourue', 'km', 'running distance',
  ];
  static const _dribblesKeywords = [
    'dribble', 'dribbling', 'ball control', 'contrôle', 'technique',
    'conduite', 'slalom',
  ];
  static const _shotsKeywords = [
    'shot', 'shooting', 'finishing', 'tir', 'frappe', 'précision',
    'accuracy', 'on target', 'finition',
  ];
  static const _injuriesKeywords = [
    'injury', 'injuries', 'blessure', 'medical', 'médical', 'absence',
    'pain', 'douleur',
  ];
  static const _heartRateKeywords = [
    'heart', 'cardiaque', 'bpm', 'resting', 'repos', 'fréquence',
    'pulse', 'pouls', 'heart rate',
  ];

  /// Converts a PlayerReport + SP Player into AI Scouting metric map.
  ///
  /// Test scores (0–100 normalized) are mapped to the ranges used by
  /// the currently trained AI dataset (dataset.json).
  static Map<String, dynamic> mapToAiMetrics({
    required sp.Player player,
    required PlayerReport report,
  }) {
    // Group test scores by AI metric
    final Map<String, List<double>> grouped = {
      'speed': [],
      'endurance': [],
      'distance': [],
      'dribbles': [],
      'shots': [],
      'injuries': [],
      'heart_rate': [],
    };

    for (final ts in report.testScores) {
      final name = ts.testName.toLowerCase();
      final cat = ts.category.toLowerCase();

      if (_matchesAny(name, _speedKeywords) || (cat == 'physical' && name.contains('sprint'))) {
        grouped['speed']!.add(ts.score);
      } else if (_matchesAny(name, _enduranceKeywords) || (cat == 'physical' && _matchesAny(name, ['endurance', 'cooper']))) {
        grouped['endurance']!.add(ts.score);
      } else if (_matchesAny(name, _distanceKeywords)) {
        grouped['distance']!.add(ts.score);
      } else if (_matchesAny(name, _dribblesKeywords) || cat == 'technical') {
        grouped['dribbles']!.add(ts.score);
      } else if (_matchesAny(name, _shotsKeywords)) {
        grouped['shots']!.add(ts.score);
      } else if (_matchesAny(name, _injuriesKeywords) || cat == 'medical') {
        grouped['injuries']!.add(ts.score);
      } else if (_matchesAny(name, _heartRateKeywords)) {
        grouped['heart_rate']!.add(ts.score);
      } else if (cat == 'physical') {
        // Unmatched physical tests → average into endurance
        grouped['endurance']!.add(ts.score);
      }
    }

    // Convert normalized scores (0–100) to model-trained ranges.
    double avg(List<double> list, double fallback) =>
        list.isEmpty ? fallback : list.reduce((a, b) => a + b) / list.length;

    final speedScore = avg(grouped['speed']!, 55);
    final enduranceScore = avg(grouped['endurance']!, 60);
    final distanceScore = grouped['distance']!.isEmpty
      ? enduranceScore
      : avg(grouped['distance']!, 60);
    final dribblesScore = avg(grouped['dribbles']!, 55);
    final shotsScore = avg(grouped['shots']!, 50);
    final healthScore = avg(grouped['injuries']!, 80);
    final cardioScore = grouped['heart_rate']!.isEmpty
      ? enduranceScore
      : avg(grouped['heart_rate']!, 70);

    final speed = _scaleScore(speedScore, 25, 97);
    final endurance = _scaleScore(enduranceScore, 25, 97);
    final distance = _scaleScore(distanceScore, 4.3, 14.6);
    final dribbles = _scaleScore(dribblesScore, 0, 96).round();
    final shots = _scaleScore(shotsScore, 0, 49).round();
    final injuries = _scaleScoreInverse(healthScore, 0, 12).round();
    final heartRate = _scaleScoreInverse(cardioScore, 58, 155).round();

    return {
      'name': '${player.firstName} ${player.lastName}',
      'age': player.age,
      'dateOfBirth': player.dateOfBirth.toIso8601String().split('T').first,
      'position': player.position,
      'club': 'ODIN Club',
      'speed': speed,
      'endurance': endurance,
      'distance': distance,
      'dribbles': dribbles,
      'shots': shots,
      'injuries': injuries,
      'heart_rate': heartRate,
      // Metadata for traceability
      '_sp_player_id': player.id,
      '_sp_overall_score': report.overallScore,
      '_sp_rank': report.rank,
      '_sp_strengths': report.strengths,
      '_sp_weaknesses': report.weaknesses,
    };
  }

  /// Send a single player's report to AI Scouting.
  /// Returns the created player data from the backend.
  static Future<AiPlayer> sendToAiScouting({
    required sp.Player player,
    required PlayerReport report,
  }) async {
    final metrics = mapToAiMetrics(player: player, report: report);

    // Remove metadata keys not expected by the API
    final apiData = Map<String, dynamic>.from(metrics)
      ..removeWhere((key, _) => key.startsWith('_sp_'));

    return await AiApiService.createPlayerFromMap(apiData);
  }

  /// Send multiple players from an event ranking to AI Scouting.
  /// Returns count of successful / failed operations.
  static Future<({int success, int failed, List<String> errors})> sendBatchToAiScouting({
    required List<({sp.Player player, PlayerReport report})> players,
  }) async {
    int success = 0;
    int failed = 0;
    final errors = <String>[];

    for (final entry in players) {
      try {
        await sendToAiScouting(
          player: entry.player,
          report: entry.report,
        );
        success++;
      } catch (e) {
        failed++;
        errors.add('${entry.player.fullName}: $e');
      }
    }

    return (success: success, failed: failed, errors: errors);
  }

  /// Converts an EventPlayer (with backend AiAnalysisResult already stored)
  /// into a fully pre-enriched AiPlayer ready for AiCampaignScreen.
  /// Uses the real test-derived metrics stored by the backend.
  static AiPlayer fromEventPlayer(EventPlayer ep) {
    final ai = ep.aiAnalysis;
    final p = ep.player;

    // Real stats from backend TestResults — never use hardcoded defaults
    final m = ai?.metrics;
    final double speed      = (m?['speed']     as num?)?.toDouble() ?? 60.0;
    final double endurance  = (m?['endurance'] as num?)?.toDouble() ?? 70.0;
    final double distance   = (m?['distance']  as num?)?.toDouble() ?? 9.5;
    final double dribbles   = (m?['dribbles']  as num?)?.toDouble() ?? 40.0;
    final double shots      = (m?['shots']     as num?)?.toDouble() ?? 20.0;
    final int    injuries   = (m?['injuries']  as num?)?.toInt()    ?? 2;
    final double heartRate  = (m?['heart_rate']as num?)?.toDouble() ?? 78.0;

    return AiPlayer(
      id: p.id,
      name: p.fullName,
      position: p.position,
      age: p.age,
      dateOfBirth: p.dateOfBirth.toIso8601String().split('T').first,
      imageUrl: p.photo,
      // Real stats from backend TestResults
      speed:      speed,
      endurance:  endurance,
      distance:   distance,
      dribbles:   dribbles,
      shots:      shots,
      injuries:   injuries,
      heartRate:  heartRate,
      // AI results from backend
      matchPercentage:  ai != null ? ai.confidence * 100 : null,
      clusterProfile:   ai?.cluster,
      aiRecommendation: ai != null ? (ai.recruited ? 'Recruter' : 'Passer') : null,
      shapExplanation:  ai?.shap,
      isEliteMatch:     (ai?.confidence ?? 0) >= 0.75,
      label: ep.recruitmentDecision == true
          ? 1
          : ep.recruitmentDecision == false
              ? 0
              : null,
    );
  }

  // ═══ HELPERS ═══

  static bool _matchesAny(String text, List<String> keywords) =>
      keywords.any((kw) => text.contains(kw));

  /// Scales a 0–100 normalized score to a target range [min, max].
  static double _scaleScore(double score100, double min, double max) =>
      min + (score100 / 100.0) * (max - min);

  /// Inverse scale: higher medical score (healthy) → fewer injuries.
  static double _scaleScoreInverse(double score100, double min, double max) =>
      max - (score100 / 100.0) * (max - min);
}
