import 'test_type.dart';

// Event Type Enum
enum EventType {
  testSession('test_session'),
  match('match'),
  evaluation('evaluation'),
  detection('detection'),
  medical('medical'),
  recovery('recovery'),
  aiAnalysis('ai_analysis');

  final String value;
  const EventType(this.value);

  static EventType fromString(String value) {
    return EventType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => EventType.testSession,
    );
  }

  TestCategory get recommendedCategory {
    switch (this) {
      case EventType.testSession:
        return TestCategory.physical;
      case EventType.match:
      case EventType.evaluation:
      case EventType.detection:
      case EventType.aiAnalysis:
        return TestCategory.technical;
      case EventType.medical:
        return TestCategory.medical;
      case EventType.recovery:
        return TestCategory.physical;
    }
  }

  bool get isSpecialized {
    return this == EventType.medical || 
           this == EventType.match || 
           this == EventType.recovery;
  }

  List<String> get defaultTestNames {
    switch (this) {
      case EventType.medical:
        return ['Poids', 'Taille', 'Masse Grasse', 'Fréq. Cardiaque'];
      case EventType.testSession:
      case EventType.recovery:
        return ['Acceleration', 'Stamina', 'Strength', 'Agility', 'Vertical Jump'];
      case EventType.match:
      case EventType.evaluation:
      case EventType.detection:
      case EventType.aiAnalysis:
        return ['Finishing', 'Passing Accuracy', 'Dribbling', 'Vision', 'Tackling'];
    }
  }
}

// Event Status Enum
enum EventStatus {
  draft('draft'),
  inProgress('in_progress'),
  completed('completed');

  final String value;
  const EventStatus(this.value);

  static EventStatus fromString(String value) {
    return EventStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => EventStatus.draft,
    );
  }
}

// Event Model
class Event {
  final String id;
  final String title;
  final EventType type;
  final DateTime date;
  final DateTime? endDate;
  final String location;
  final EventStatus status;
  final String? description;
  final String? coachId;
  final List<String> testTypes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Event({
    required this.id,
    required this.title,
    required this.type,
    required this.date,
    this.endDate,
    required this.location,
    required this.status,
    this.description,
    this.coachId,
    required this.testTypes,
    this.createdAt,
    this.updatedAt,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['_id'] ?? json['id'],
      title: json['title'],
      type: EventType.fromString(json['type']),
      date: DateTime.parse(json['date']),
      endDate:
          json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      location: json['location'],
      status: EventStatus.fromString(json['status']),
      description: json['description'],
      // Handle coachId whether it's populated (Map), ID string, or null
      coachId: json['coachId'] is Map
          ? (json['coachId']['_id'] ?? json['coachId']['id'])
          : (json['coachId'] != null && json['coachId'].toString().isNotEmpty
              ? json['coachId'].toString()
              : null),
      // Handle testTypes whether they are populated objects or ID strings
      testTypes: (json['testTypes'] as List?)?.map((item) {
            if (item is Map) {
              return (item['_id'] ?? item['id'] ?? '').toString();
            }
            return item.toString();
          }).toList() ??
          [],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'type': type.value,
      'date': date.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'location': location,
      'status': status.value,
      'description': description,
      if (coachId != null && coachId!.isNotEmpty) 'coachId': coachId,
      'testTypes': testTypes,
    };
  }

  String get typeLabel {
    switch (type) {
      case EventType.testSession:
        return 'Session de Test';
      case EventType.match:
        return 'Match';
      case EventType.evaluation:
        return 'Évaluation';
      case EventType.detection:
        return 'Détection';
      case EventType.medical:
        return 'Médical';
      case EventType.recovery:
        return 'Récupération';
      case EventType.aiAnalysis:
        return 'Analyse IA';
    }
  }

  String get statusLabel {
    switch (status) {
      case EventStatus.draft:
        return 'Brouillon';
      case EventStatus.inProgress:
        return 'En cours';
      case EventStatus.completed:
        return 'Terminé';
    }
  }

  bool get isEditable => status == EventStatus.draft;
  bool get isActive => status == EventStatus.inProgress;
  bool get isCompleted => status == EventStatus.completed;
}
