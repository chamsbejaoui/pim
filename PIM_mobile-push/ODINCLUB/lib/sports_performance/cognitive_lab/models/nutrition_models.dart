// Models for the Nutrition Lab module

enum MealType {
  preMatch('PRE_MATCH', 'Repas Pré-Match'),
  postMatchRecovery('POST_MATCH_RECOVERY', 'Récupération Post-Match'),
  highCarb('HIGH_CARB', 'Repas Riche en Glucides'),
  maintenance('MAINTENANCE', 'Repas de Maintien'),
  hydration('HYDRATION', 'Hydratation');

  const MealType(this.value, this.label);
  final String value;
  final String label;
}

class PhysicalProfile {
  final String userId;
  final double weightKg;
  final double heightCm;
  final double tourTaille;
  final double tourCou;
  final DateTime dateNaissance;
  final String position;

  // Champs calculés par le backend (optionnels ici pour la création)
  final double? graissePercent;
  final double? masseMuscul;
  final int? bmr;
  final double? eauBase;
  final double? eauEntrainement;
  final double? eauMatch;

  PhysicalProfile({
    required this.userId,
    required this.weightKg,
    required this.heightCm,
    required this.tourTaille,
    required this.tourCou,
    required this.dateNaissance,
    required this.position,
    this.graissePercent,
    this.masseMuscul,
    this.bmr,
    this.eauBase,
    this.eauEntrainement,
    this.eauMatch,
  });

  double get bmi => weightKg / ((heightCm / 100) * (heightCm / 100));

  factory PhysicalProfile.fromJson(Map<String, dynamic> json) {
    return PhysicalProfile(
      userId: json['userId'] ?? '',
      weightKg: (json['weightKg'] as num?)?.toDouble() ?? 0,
      heightCm: (json['heightCm'] as num?)?.toDouble() ?? 0,
      tourTaille: (json['tourTaille'] as num?)?.toDouble() ?? 0,
      tourCou: (json['tourCou'] as num?)?.toDouble() ?? 0,
      dateNaissance: json['dateNaissance'] != null ? DateTime.parse(json['dateNaissance']) : DateTime.now(),
      position: json['position'] ?? 'Unknown',
      graissePercent: (json['graissePercent'] as num?)?.toDouble(),
      masseMuscul: (json['masseMuscul'] as num?)?.toDouble(),
      bmr: (json['bmr'] as num?)?.toInt(),
      eauBase: (json['eauBase'] as num?)?.toDouble(),
      eauEntrainement: (json['eauEntrainement'] as num?)?.toDouble(),
      eauMatch: (json['eauMatch'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'weightKg': weightKg,
    'heightCm': heightCm,
    'tourTaille': tourTaille,
    'tourCou': tourCou,
    'dateNaissance': dateNaissance.toIso8601String(),
    'position': position,
  };
}

class NutritionLog {
  final String userId;
  final String mealType;
  final double carbsGrams;
  final double proteinsGrams;
  final double fatsGrams;
  final double hydrationMl;

  NutritionLog({
    required this.userId,
    required this.mealType,
    this.carbsGrams = 0,
    this.proteinsGrams = 0,
    this.fatsGrams = 0,
    this.hydrationMl = 0,
  });

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'mealType': mealType,
    'carbsGrams': carbsGrams,
    'proteinsGrams': proteinsGrams,
    'fatsGrams': fatsGrams,
    'hydrationMl': hydrationMl,
  };
}

class MetabolicStatus {
  final bool cognitiveFatigueDetected;
  final String alertMessage;
  final String? error;
  final PhysicalProfile? profileData;
  final Map<String, double> targets;
  final Map<String, double> current;
  final Map<String, double> deficits;

  MetabolicStatus({
    required this.cognitiveFatigueDetected,
    required this.alertMessage,
    this.error,
    this.profileData,
    required this.targets,
    required this.current,
    required this.deficits,
  });

  factory MetabolicStatus.fromJson(Map<String, dynamic> json) {
    return MetabolicStatus(
      cognitiveFatigueDetected: json['cognitiveFatigueDetected'] ?? false,
      alertMessage: json['alertMessage'] ?? '',
      error: json['error'],
      profileData: json['profileData'] != null ? PhysicalProfile.fromJson(json['profileData'] as Map<String, dynamic>) : null,
      targets: Map<String, double>.from(
        (json['targets'] as Map<String, dynamic>? ?? {}).map(
          (k, v) => MapEntry(k, (v as num).toDouble()),
        )
      ),
      current: Map<String, double>.from(
        (json['current'] as Map<String, dynamic>? ?? {}).map(
          (k, v) => MapEntry(k, (v as num).toDouble()),
        )
      ),
      deficits: Map<String, double>.from(
        (json['deficits'] as Map<String, dynamic>? ?? {}).map(
          (k, v) => MapEntry(k, (v as num).toDouble()),
        )
      ),
    );
  }
}

class MealPlan {
  final String name;
  final double kcal;
  final double carbs;
  final double proteins;
  final double fats;
  final String description;
  final String icon;

  MealPlan({
    required this.name,
    required this.kcal,
    required this.carbs,
    required this.proteins,
    required this.fats,
    required this.description,
    required this.icon,
  });

  factory MealPlan.fromJson(Map<String, dynamic> json) {
    return MealPlan(
      name: json['name'] ?? '',
      kcal: (json['kcal'] as num?)?.toDouble() ?? 0,
      carbs: (json['carbs'] as num?)?.toDouble() ?? 0,
      proteins: (json['proteins'] as num?)?.toDouble() ?? 0,
      fats: (json['fats'] as num?)?.toDouble() ?? 0,
      description: json['description'] ?? '',
      icon: json['icon'] ?? 'fastfood',
    );
  }
}

class DailyMealPlan {
  final String day;
  final double totalKcal;
  final List<MealPlan> meals;
  final String advice;

  DailyMealPlan({
    required this.day,
    required this.totalKcal,
    required this.meals,
    required this.advice,
  });

  factory DailyMealPlan.fromJson(Map<String, dynamic> json) {
    return DailyMealPlan(
      day: json['day'] ?? '',
      totalKcal: (json['totalKcal'] as num?)?.toDouble() ?? 0,
      meals: (json['meals'] as List? ?? [])
          .map((m) => MealPlan.fromJson(m as Map<String, dynamic>))
          .toList(),
      advice: json['advice'] ?? '',
    );
  }
}

class WeeklyMealPlan {
  final String userId;
  final int weekNumber;
  final List<DailyMealPlan> days;

  WeeklyMealPlan({
    required this.userId,
    required this.weekNumber,
    required this.days,
  });

  factory WeeklyMealPlan.fromJson(Map<String, dynamic> json) {
    return WeeklyMealPlan(
      userId: json['userId'] ?? '',
      weekNumber: json['weekNumber'] ?? 1,
      days: (json['days'] as List? ?? [])
          .map((d) => DailyMealPlan.fromJson(d as Map<String, dynamic>))
          .toList(),
    );
  }
}
