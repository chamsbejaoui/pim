class PlayerModel {
  const PlayerModel({
    required this.id,
    required this.name,
    required this.position,
    required this.baseFitness,
    required this.injuryHistory,
    this.lastMatchId,
    this.lastMatchAt,
    this.lastMatchLoad,
    this.lastMatchFatigue,
    this.lastMatchInjuryProbability,
    this.isInjured,
    this.lastInjuryType,
    this.lastRecoveryDays,
    this.lastSeverity,
    this.lastInjuryProbability,
  });

  final String id;
  final String name;
  final String position;
  final int baseFitness;
  final int injuryHistory;
  final String? lastMatchId;
  final DateTime? lastMatchAt;
  final int? lastMatchLoad;
  final int? lastMatchFatigue;
  final double? lastMatchInjuryProbability;
  final bool? isInjured;
  final String? lastInjuryType;
  final int? lastRecoveryDays;
  final String? lastSeverity;
  final double? lastInjuryProbability;

  factory PlayerModel.fromJson(Map<String, dynamic> json) {
    return PlayerModel(
      id: _stringFrom(json, ['id', '_id', 'playerId']) ?? '',
      name: _stringFrom(json, ['name', 'fullName', 'playerName']) ?? 'Unknown',
      position: _stringFrom(json, ['position', 'role']) ?? 'Unknown',
      baseFitness: _intFrom(json, ['baseFitness', 'fitness', 'base_fitness']),
      injuryHistory: _intFrom(json, [
        'injuryHistory',
        'injuries',
        'injury_history',
      ]),
      lastMatchId: _stringFrom(json, ['lastMatchId']),
      lastMatchAt: _dateFrom(json, ['lastMatchAt']),
      lastMatchLoad: _intFrom(json, ['lastMatchLoad']),
      lastMatchFatigue: _intFrom(json, ['lastMatchFatigue']),
      lastMatchInjuryProbability:
          _doubleFrom(json, ['lastMatchInjuryProbability']),
      isInjured: json['isInjured'] == true,
      lastInjuryType: _stringFrom(json, ['lastInjuryType']),
      lastRecoveryDays: _intFrom(json, ['lastRecoveryDays']),
      lastSeverity: _stringFrom(json, ['lastSeverity']),
      lastInjuryProbability: _doubleFrom(json, ['lastInjuryProbability']),
    );
  }

  static String? _stringFrom(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is String && value.isNotEmpty) {
        return value;
      }
      if (value != null) {
        return value.toString();
      }
    }
    return null;
  }

  static int _intFrom(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is int) {
        return value;
      }
      if (value is double) {
        return value.round();
      }
      if (value is String) {
        final parsed = int.tryParse(value);
        if (parsed != null) {
          return parsed;
        }
      }
    }
    return 0;
  }

  static double? _doubleFrom(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is num) {
        return value.toDouble();
      }
      if (value is String) {
        final parsed = double.tryParse(value);
        if (parsed != null) {
          return parsed;
        }
      }
    }
    return null;
  }

  static DateTime? _dateFrom(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is String) {
        final parsed = DateTime.tryParse(value);
        if (parsed != null) {
          return parsed;
        }
      }
    }
    return null;
  }
}
