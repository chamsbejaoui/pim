/// Model representing a scouting player with AI-enriched fields.
/// Matches the Backend /players schema and AI prediction response.
class AiPlayer {
  final String? id;
  final String name;
  final double speed;
  final double endurance;
  final double distance;
  final double dribbles;
  final double shots;
  final int injuries;
  final double heartRate;
  final int? label;
  final String? position;

  // UI-specific fields
  final String? imageUrl;
  final int? age;
  final String? dateOfBirth;
  final String? club;
  final String? estimatedValue;
  final double? matchPercentage;
  final List<String> tags;
  final bool isEliteMatch;
  final Map<String, dynamic>? shapExplanation;
  final String? clusterProfile;
  final String? aiRecommendation;
  final String status;

  const AiPlayer({
    this.id,
    required this.name,
    required this.speed,
    required this.endurance,
    required this.distance,
    required this.dribbles,
    required this.shots,
    required this.injuries,
    required this.heartRate,
    this.label,
    this.position,
    this.imageUrl,
    this.age,
    this.dateOfBirth,
    this.club,
    this.estimatedValue,
    this.matchPercentage,
    this.tags = const [],
    this.isEliteMatch = false,
    this.shapExplanation,
    this.clusterProfile,
    this.aiRecommendation,
    this.status = 'active',
  });

  factory AiPlayer.fromJson(Map<String, dynamic> json) {
    // Backend stores firstName + lastName separately; 'name' is a fallback
    final String firstName = json['firstName'] as String? ?? '';
    final String lastName  = json['lastName']  as String? ?? '';
    final String combined  = (json['name'] as String?)?.trim() ?? '';
    final String resolvedName = combined.isNotEmpty
        ? combined
        : '${firstName} ${lastName}'.trim().isEmpty
            ? 'Unknown'
            : '${firstName} ${lastName}'.trim();
    return AiPlayer(
      id: json['_id'] as String?,
      name: resolvedName,
      speed: (json['speed'] as num?)?.toDouble() ?? 0,
      endurance: (json['endurance'] as num?)?.toDouble() ?? 0,
      distance: (json['distance'] as num?)?.toDouble() ?? 0,
      dribbles: (json['dribbles'] as num?)?.toDouble() ?? 0,
      shots: (json['shots'] as num?)?.toDouble() ?? 0,
      injuries: (json['injuries'] as num?)?.toInt() ?? 0,
      heartRate: (json['heart_rate'] as num?)?.toDouble() ?? 0,
      label: json['label'] is int ? json['label'] as int : null,
      position: json['position'] as String?,
      imageUrl: json['imageUrl'] as String?,
      age: json['age'] as int?,
      dateOfBirth: json['dateOfBirth'] as String?,
      club: json['club'] as String?,
      estimatedValue: json['estimatedValue'] as String?,
      matchPercentage: (json['matchPercentage'] as num?)?.toDouble(),
      tags: (json['tags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      isEliteMatch: json['isEliteMatch'] as bool? ?? false,
      shapExplanation: json['shapExplanation'] as Map<String, dynamic>?,
      clusterProfile: json['clusterProfile'] as String?,
      aiRecommendation: json['aiRecommendation'] as String?,
      status: json['status'] as String? ?? 'active',
    );
  }

  /// Split the display name into firstName/lastName for the backend.
  String get _firstName {
    final parts = name.trim().split(' ');
    return parts.isNotEmpty ? parts.first : name;
  }
  String get _lastName {
    final parts = name.trim().split(' ');
    return parts.length > 1 ? parts.sublist(1).join(' ') : '';
  }

  Map<String, dynamic> toJson() {
    return {
      'firstName': _firstName,
      'lastName':  _lastName,
      'speed': speed,
      'endurance': endurance,
      'distance': distance,
      'dribbles': dribbles,
      'shots': shots,
      'injuries': injuries,
      'heart_rate': heartRate,
      if (label != null) 'label': label,
      if (position != null) 'position': position,
      if (dateOfBirth != null) 'dateOfBirth': dateOfBirth,
      'status': status,
    };
  }

  double get computedMatchPercentage {
    if (matchPercentage != null) return matchPercentage!;
    final avg = (speed +
            endurance +
            (dribbles / 2).clamp(0, 100) +
            (shots * 5).clamp(0, 100)) /
        4;
    return avg.clamp(0, 100);
  }

  List<String> get computedTags {
    if (tags.isNotEmpty) return tags;
    final result = <String>[];
    if (clusterProfile != null) result.add(clusterProfile!);
    if (speed >= 80) result.add('Pace');
    if (endurance >= 80) result.add('Endurance');
    if (dribbles >= 30) result.add('Dribbling');
    if (shots >= 5) result.add('Finishing');
    if (distance >= 10) result.add('Stamina');
    if (heartRate <= 65) result.add('Composure');
    return result;
  }

  AiPlayer copyWith({
    String? id,
    String? name,
    double? speed,
    double? endurance,
    double? distance,
    double? dribbles,
    double? shots,
    int? injuries,
    double? heartRate,
    int? label,
    String? position,
    String? imageUrl,
    int? age,
    String? dateOfBirth,
    String? club,
    String? estimatedValue,
    double? matchPercentage,
    List<String>? tags,
    bool? isEliteMatch,
    Map<String, dynamic>? shapExplanation,
    String? clusterProfile,
    String? aiRecommendation,
    String? status,
  }) {
    return AiPlayer(
      id: id ?? this.id,
      name: name ?? this.name,
      speed: speed ?? this.speed,
      endurance: endurance ?? this.endurance,
      distance: distance ?? this.distance,
      dribbles: dribbles ?? this.dribbles,
      shots: shots ?? this.shots,
      injuries: injuries ?? this.injuries,
      heartRate: heartRate ?? this.heartRate,
      label: label ?? this.label,
      position: position ?? this.position,
      imageUrl: imageUrl ?? this.imageUrl,
      age: age ?? this.age,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      club: club ?? this.club,
      estimatedValue: estimatedValue ?? this.estimatedValue,
      matchPercentage: matchPercentage ?? this.matchPercentage,
      tags: tags ?? this.tags,
      isEliteMatch: isEliteMatch ?? this.isEliteMatch,
      shapExplanation: shapExplanation ?? this.shapExplanation,
      clusterProfile: clusterProfile ?? this.clusterProfile,
      aiRecommendation: aiRecommendation ?? this.aiRecommendation,
      status: status ?? this.status,
    );
  }
}
