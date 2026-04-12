class Player {
  final String id;
  final String clubId;
  final String firstName;
  final String lastName;
  final DateTime? dateOfBirth;
  final String? nationality;
  final String? photoUrl;
  final String position;
  final String? preferredFoot;
  final int? jerseyNumber;
  final double? height;
  final double? weight;
  final String status;
  final DateTime? returnDate;
  final DateTime? contractStartDate;
  final DateTime? contractEndDate;
  final String? teamId;
  final Map<String, dynamic>? team;
  final String? categoryId;
  final Map<String, dynamic>? category;
  final int? aiScore;
  final Map<String, dynamic>? stats;
  final bool? isProspect;
  final double? salary;
  final String? medicalNotes;
  final String? createdBy;
  final DateTime? createdAt;

  Player({
    required this.id,
    required this.clubId,
    required this.firstName,
    required this.lastName,
    this.dateOfBirth,
    this.nationality,
    this.photoUrl,
    required this.position,
    this.preferredFoot,
    this.jerseyNumber,
    this.height,
    this.weight,
    this.status = 'active',
    this.returnDate,
    this.contractStartDate,
    this.contractEndDate,
    this.teamId,
    this.team,
    this.categoryId,
    this.category,
    this.aiScore,
    this.stats,
    this.isProspect,
    this.salary,
    this.medicalNotes,
    this.createdBy,
    this.createdAt,
  });

  String get fullName => '$firstName $lastName';
  String get initials =>
      '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}'.toUpperCase();
  String? get teamName => team?['name'];
  String? get categoryName => category?['name'];

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      id: json['id'] ?? '',
      clubId: json['clubId'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.tryParse(json['dateOfBirth'].toString())
          : null,
      nationality: json['nationality'],
      photoUrl: json['photoUrl'],
      position: json['position'] ?? '',
      preferredFoot: json['preferredFoot'],
      jerseyNumber: json['jerseyNumber'] != null
          ? int.tryParse(json['jerseyNumber'].toString())
          : null,
      height: json['height'] != null
          ? double.tryParse(json['height'].toString())
          : null,
      weight: json['weight'] != null
          ? double.tryParse(json['weight'].toString())
          : null,
      status: json['status'] ?? 'active',
      returnDate: json['returnDate'] != null
          ? DateTime.tryParse(json['returnDate'].toString())
          : null,
      contractStartDate: json['contractStartDate'] != null
          ? DateTime.tryParse(json['contractStartDate'].toString())
          : null,
      contractEndDate: json['contractEndDate'] != null
          ? DateTime.tryParse(json['contractEndDate'].toString())
          : null,
      teamId: json['teamId'],
      team: json['team'] is Map<String, dynamic> ? json['team'] : null,
      categoryId: json['categoryId'],
      category: json['category'] is Map<String, dynamic> ? json['category'] : null,
      aiScore: json['aiScore'] != null ? int.tryParse(json['aiScore'].toString()) : null,
      stats: json['stats'] is Map<String, dynamic> ? json['stats'] : null,
      isProspect: json['isProspect'] == true || json['isProspect'] == 1 || json['isProspect'] == '1',
      salary: json['salary'] != null ? double.tryParse(json['salary'].toString()) : null,
      medicalNotes: json['medicalNotes'],
      createdBy: json['createdBy'] is Map ? json['createdBy']['firstName'] : json['createdBy'],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'firstName': firstName,
    'lastName': lastName,
    'dateOfBirth': dateOfBirth?.toIso8601String().split('T').first,
    'nationality': nationality,
    'photoUrl': photoUrl,
    'position': position,
    'preferredFoot': preferredFoot,
    'jerseyNumber': jerseyNumber,
    'height': height,
    'weight': weight,
    'status': status,
    'teamId': teamId,
    'categoryId': categoryId,
    'aiScore': aiScore,
    'stats': stats,
    'isProspect': isProspect,
    'salary': salary,
    'medicalNotes': medicalNotes,
    'contractStartDate': contractStartDate?.toIso8601String().split('T').first,
    'contractEndDate': contractEndDate?.toIso8601String().split('T').first,
  };
}

class PlayerHistory {
  final String id;
  final String playerId;
  final String eventType;
  final DateTime? eventDate;
  final String? description;
  final String? previousValue;
  final String? newValue;
  final String? createdBy;
  final DateTime? createdAt;

  PlayerHistory({
    required this.id,
    required this.playerId,
    required this.eventType,
    this.eventDate,
    this.description,
    this.previousValue,
    this.newValue,
    this.createdBy,
    this.createdAt,
  });

  factory PlayerHistory.fromJson(Map<String, dynamic> json) {
    return PlayerHistory(
      id: json['id'] ?? '',
      playerId: json['playerId'] ?? '',
      eventType: json['eventType'] ?? '',
      eventDate: json['eventDate'] != null
          ? DateTime.tryParse(json['eventDate'].toString())
          : null,
      description: json['description'],
      previousValue: json['previousValue'],
      newValue: json['newValue'],
      createdBy: json['createdBy'],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }
}
