class SimulationResultModel {
  const SimulationResultModel({
    required this.playerId,
    required this.name,
    required this.fatigue,
    required this.load,
    required this.injuryProbability,
    required this.status,
    required this.injuryType,
    required this.recoveryDays,
    required this.severity,
    required this.playedMatch,
    required this.playedAt,
  });

  final String playerId;
  final String name;
  final double fatigue;
  final double load;
  final double injuryProbability;
  final String status;
  final String? injuryType;
  final int? recoveryDays;
  final String? severity;
  final bool playedMatch;
  final DateTime? playedAt;

  factory SimulationResultModel.fromJson(Map<String, dynamic> json) {
    return SimulationResultModel(
      playerId: (json['playerId'] ?? json['_id'] ?? '').toString(),
      name: (json['name'] ?? 'Unknown').toString(),
      fatigue: _doubleFrom(json, 'fatigue'),
      load: _doubleFrom(json, 'load'),
      injuryProbability: _doubleFrom(json, 'injuryProbability'),
      status: (json['status'] ?? 'SAFE').toString(),
      injuryType: json['injuryType']?.toString(),
      recoveryDays: _intFrom(json, 'recoveryDays'),
      severity: json['severity']?.toString(),
      playedMatch: json['playedMatch'] == true,
      playedAt: _dateFrom(json, 'playedAt'),
    );
  }

  static DateTime? _dateFrom(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  static double _doubleFrom(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int? _intFrom(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '');
  }
}
