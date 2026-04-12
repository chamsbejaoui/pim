import 'player.dart';

// Participation Status Enum
enum ParticipationStatus {
  invited('invited'),
  confirmed('confirmed'),
  completed('completed'),
  absent('absent');

  final String value;
  const ParticipationStatus(this.value);

  static ParticipationStatus fromString(String value) {
    return ParticipationStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ParticipationStatus.invited,
    );
  }
}

/// Résultat de l'analyse IA stocké directement dans l'EventPlayer.
class AiAnalysisResult {
  final bool recruited;
  final double confidence; // 0.0 – 1.0
  final String? cluster;
  final double? potentialScore;
  final Map<String, dynamic>? shap;
  final DateTime analyzedAt;
  /// Real test-derived stats saved by backend — speed, endurance, distance, etc.
  final Map<String, dynamic>? metrics;

  AiAnalysisResult({
    required this.recruited,
    required this.confidence,
    this.cluster,
    this.potentialScore,
    this.shap,
    required this.analyzedAt,
    this.metrics,
  });

  factory AiAnalysisResult.fromJson(Map<String, dynamic> json) {
    return AiAnalysisResult(
      recruited: json['recruited'] ?? false,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      cluster: json['cluster'],
      potentialScore: (json['potentialScore'] as num?)?.toDouble(),
      shap: json['shap'] != null ? Map<String, dynamic>.from(json['shap']) : null,
      analyzedAt: json['analyzedAt'] != null
          ? DateTime.parse(json['analyzedAt'])
          : DateTime.now(),
      metrics: json['metrics'] != null
          ? Map<String, dynamic>.from(json['metrics'])
          : null,
    );
  }
}

// Event Player Model
class EventPlayer {
  final String id;
  final String eventId;
  final Player player;
  final ParticipationStatus status;
  final String? coachNotes;
  final DateTime joinedAt;
  final DateTime? completedAt;

  /// Résultat IA stocké après POST /api/events/:id/analyze
  final AiAnalysisResult? aiAnalysis;

  /// Décision finale du coach (true = recruter, false = passer)
  final bool? recruitmentDecision;

  EventPlayer({
    required this.id,
    required this.eventId,
    required this.player,
    required this.status,
    this.coachNotes,
    required this.joinedAt,
    this.completedAt,
    this.aiAnalysis,
    this.recruitmentDecision,
  });

  factory EventPlayer.fromJson(Map<String, dynamic> json) {
    return EventPlayer(
      id: json['_id'] ?? json['id'],
      eventId: json['eventId'],
      player: json['playerId'] is String
          ? Player(
              id: json['playerId'],
              firstName: '',
              lastName: '',
              dateOfBirth: DateTime.now(),
              position: '',
              strongFoot: 'Right',
            )
          : Player.fromJson(json['playerId']),
      status: ParticipationStatus.fromString(json['status']),
      coachNotes: json['coachNotes'],
      joinedAt: DateTime.parse(json['joinedAt']),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
      aiAnalysis: json['aiAnalysis'] != null
          ? AiAnalysisResult.fromJson(json['aiAnalysis'])
          : null,
      recruitmentDecision: json['recruitmentDecision'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'eventId': eventId,
      'playerId': player.id,
      'status': status.value,
      'coachNotes': coachNotes,
      'joinedAt': joinedAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  String get statusLabel {
    switch (status) {
      case ParticipationStatus.invited:
        return 'Invité';
      case ParticipationStatus.confirmed:
        return 'Confirmé';
      case ParticipationStatus.completed:
        return 'Complété';
      case ParticipationStatus.absent:
        return 'Absent';
    }
  }

  bool get isCompleted => status == ParticipationStatus.completed;
  bool get isConfirmed => status == ParticipationStatus.confirmed;
  bool get hasAiAnalysis => aiAnalysis != null;
}
