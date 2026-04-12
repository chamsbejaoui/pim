// Test Category Enum
enum TestCategory {
  physical('physical'),
  technical('technical'),
  medical('medical'),
  mental('mental');

  final String value;
  const TestCategory(this.value);

  static TestCategory fromString(String value) {
    return TestCategory.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TestCategory.physical,
    );
  }

  String get label {
    switch (this) {
      case TestCategory.physical: return 'Physique';
      case TestCategory.technical: return 'Technique';
      case TestCategory.medical: return 'Médical';
      case TestCategory.mental: return 'Mental';
    }
  }
}

// Scoring Method Enum
enum ScoringMethod {
  higherBetter('higher_better'),
  lowerBetter('lower_better'),
  range('range');

  final String value;
  const ScoringMethod(this.value);

  static ScoringMethod fromString(String value) {
    return ScoringMethod.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ScoringMethod.higherBetter,
    );
  }
}

// Optimal Range Model
class OptimalRange {
  final double min;
  final double max;

  OptimalRange({
    required this.min,
    required this.max,
  });

  factory OptimalRange.fromJson(Map<String, dynamic> json) {
    return OptimalRange(
      min: json['min'].toDouble(),
      max: json['max'].toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'min': min,
      'max': max,
    };
  }
}

// Test Type Model
class TestType {
  final String id;
  final String name;
  final TestCategory category;
  final String description;
  final String unit;
  final ScoringMethod scoringMethod;
  final double? minThreshold;
  final double? maxThreshold;
  final OptimalRange? optimalRange;
  final double weight;
  final double? eliteThreshold;
  final double? baselineThreshold;
  final bool betterIsHigher;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  TestType({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.unit,
    required this.scoringMethod,
    this.minThreshold,
    this.maxThreshold,
    this.optimalRange,
    required this.weight,
    this.eliteThreshold,
    this.baselineThreshold,
    required this.betterIsHigher,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  factory TestType.fromJson(Map<String, dynamic> json) {
    return TestType(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      category: TestCategory.fromString(json['category'] ?? ''),
      description: json['description'] ?? '',
      unit: json['unit'] ?? '',
      scoringMethod: ScoringMethod.fromString(json['scoringMethod'] ?? ''),
      minThreshold: json['minThreshold']?.toDouble() ?? json['minValue']?.toDouble(),
      maxThreshold: json['maxThreshold']?.toDouble() ?? json['maxValue']?.toDouble(),
      optimalRange: json['optimalRange'] != null
          ? OptimalRange.fromJson(json['optimalRange'])
          : null,
      weight: (json['weight'] ?? 1.0).toDouble(),
      eliteThreshold: json['eliteThreshold']?.toDouble(),
      baselineThreshold: json['baselineThreshold']?.toDouble(),
      betterIsHigher: json['betterIsHigher'] ?? true,
      isActive: json['isActive'] ?? true,
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
      'name': name,
      'category': category.value,
      'description': description,
      'unit': unit,
      'scoringMethod': scoringMethod.value,
      'minThreshold': minThreshold,
      'maxThreshold': maxThreshold,
      'optimalRange': optimalRange?.toJson(),
      'weight': weight,
      'eliteThreshold': eliteThreshold,
      'baselineThreshold': baselineThreshold,
      'betterIsHigher': betterIsHigher,
      'isActive': isActive,
    };
  }

  String get categoryLabel {
    switch (category) {
      case TestCategory.physical:
        return 'Physique';
      case TestCategory.technical:
        return 'Technique';
      case TestCategory.medical:
        return 'Médical';
      case TestCategory.mental:
        return 'Mental';
    }
  }

  String get scoringMethodLabel {
    switch (scoringMethod) {
      case ScoringMethod.higherBetter:
        return 'Plus élevé = mieux';
      case ScoringMethod.lowerBetter:
        return 'Plus bas = mieux';
      case ScoringMethod.range:
        return 'Plage optimale';
    }
  }
}
