import 'test_type.dart';

// Test Result Model
class TestResult {
  final String id;
  final String eventPlayerId;
  final TestType testType;
  final double rawValue;
  final double normalizedScore;
  final String? notes;
  final DateTime recordedAt;

  TestResult({
    required this.id,
    required this.eventPlayerId,
    required this.testType,
    required this.rawValue,
    required this.normalizedScore,
    this.notes,
    required this.recordedAt,
  });

  factory TestResult.fromJson(Map<String, dynamic> json) {
    return TestResult(
      id: json['_id'] ?? json['id'],
      eventPlayerId: json['eventPlayerId'],
      testType: json['testTypeId'] is String
          ? TestType(
              id: json['testTypeId'],
              name: '',
              category: TestCategory.physical,
              description: '',
              unit: '',
              scoringMethod: ScoringMethod.higherBetter,
              weight: 1.0,
              betterIsHigher: true,
              isActive: true,
            )
          : TestType.fromJson(json['testTypeId']),
      rawValue: json['rawValue'].toDouble(),
      normalizedScore: json['normalizedScore'].toDouble(),
      notes: json['notes'],
      recordedAt: DateTime.parse(json['recordedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'eventPlayerId': eventPlayerId,
      'testTypeId': testType.id,
      'rawValue': rawValue,
      'notes': notes,
    };
  }

  String get scoreFormatted => '${normalizedScore.toStringAsFixed(1)}/100';

  String get performanceLevel {
    if (normalizedScore >= 90) return 'Excellent';
    if (normalizedScore >= 75) return 'Très bon';
    if (normalizedScore >= 60) return 'Bon';
    if (normalizedScore >= 50) return 'Moyen';
    return 'À améliorer';
  }
}
