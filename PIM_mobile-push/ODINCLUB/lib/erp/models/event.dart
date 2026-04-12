class Event {
  final String id;
  final String clubId;
  final String eventType;
  final String title;
  final String? description;
  final DateTime startDate;
  final DateTime endDate;
  final bool allDay;
  final String? location;
  final Map<String, dynamic>? eventDetails;
  final String status;
  final String visibility;
  final String? teamId;
  final Map<String, dynamic>? team;
  final int? homeScore;
  final int? awayScore;
  final bool reminderEnabled;
  final int reminderMinutes;
  final String? createdBy;
  final DateTime? createdAt;

  Event({
    required this.id,
    required this.clubId,
    required this.eventType,
    required this.title,
    this.description,
    required this.startDate,
    required this.endDate,
    this.allDay = false,
    this.location,
    this.eventDetails,
    this.status = 'scheduled',
    this.visibility = 'club',
    this.teamId,
    this.team,
    this.homeScore,
    this.awayScore,
    this.reminderEnabled = true,
    this.reminderMinutes = 60,
    this.createdBy,
    this.createdAt,
  });

  String? get teamName => team?['name'];

  String get eventTypeLabel {
    switch (eventType) {
      case 'match': return 'Match';
      case 'detection': return 'Scouting';
      case 'entrainement': return 'Entraînement';
      case 'reunion': return 'Réunion';
      case 'test_physique': return 'Test Physique';
      default: return 'Autre';
    }
  }

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'] ?? '',
      clubId: json['clubId'] ?? '',
      eventType: json['eventType'] ?? 'autre',
      title: json['title'] ?? '',
      description: json['description'],
      startDate: DateTime.parse(json['startDate'] ?? DateTime.now().toIso8601String()),
      endDate: DateTime.parse(json['endDate'] ?? DateTime.now().toIso8601String()),
      allDay: json['allDay'] ?? false,
      location: json['location'],
      eventDetails: json['eventDetails'] is Map<String, dynamic>
          ? json['eventDetails']
          : null,
      status: json['status'] ?? 'scheduled',
      visibility: json['visibility'] ?? 'club',
      teamId: json['teamId'],
      team: json['team'] is Map<String, dynamic> ? json['team'] : null,
      homeScore: json['homeScore'] != null ? int.tryParse(json['homeScore'].toString()) : null,
      awayScore: json['awayScore'] != null ? int.tryParse(json['awayScore'].toString()) : null,
      reminderEnabled: json['reminderEnabled'] ?? true,
      reminderMinutes: json['reminderMinutes'] ?? 60,
      createdBy: json['createdBy'],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'eventType': eventType,
    'title': title,
    'description': description,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate.toIso8601String(),
    'allDay': allDay,
    'location': location,
    'eventDetails': eventDetails,
    'visibility': visibility,
    'teamId': teamId,
    'homeScore': homeScore,
    'awayScore': awayScore,
    'reminderEnabled': reminderEnabled,
    'reminderMinutes': reminderMinutes,
  };
}

class EventParticipant {
  final String id;
  final String eventId;
  final String participantType;
  final String participantId;
  final String status;
  final double? performanceRating;
  final DateTime? responseDate;

  EventParticipant({
    required this.id,
    required this.eventId,
    required this.participantType,
    required this.participantId,
    this.status = 'pending',
    this.performanceRating,
    this.responseDate,
  });

  factory EventParticipant.fromJson(Map<String, dynamic> json) {
    return EventParticipant(
      id: json['id'] ?? '',
      eventId: json['eventId'] ?? '',
      participantType: json['participantType'] ?? '',
      participantId: json['participantId'] ?? '',
      status: json['status'] ?? 'pending',
      performanceRating: json['performanceRating'] != null ? double.tryParse(json['performanceRating'].toString()) : null,
      responseDate: json['responseDate'] != null
          ? DateTime.tryParse(json['responseDate'].toString())
          : null,
    );
  }
}
