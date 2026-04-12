class MedicalHistoryRecordModel {
  const MedicalHistoryRecordModel({
    required this.injuryProbability,
    required this.createdAt,
  });

  final double injuryProbability;
  final DateTime createdAt;

  factory MedicalHistoryRecordModel.fromJson(Map<String, dynamic> json) {
    final createdAtValue = json['createdAt'];
    DateTime parsedDate;
    if (createdAtValue is String) {
      parsedDate = DateTime.tryParse(createdAtValue) ?? DateTime.now();
    } else if (createdAtValue is int) {
      parsedDate = DateTime.fromMillisecondsSinceEpoch(createdAtValue);
    } else {
      parsedDate = DateTime.now();
    }

    return MedicalHistoryRecordModel(
      injuryProbability: _doubleFrom(json['injuryProbability']),
      createdAt: parsedDate,
    );
  }

  static double _doubleFrom(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }
}
