import '../models/medical_result_model.dart';
import '../models/nutrition_model.dart';
import '../models/player_model.dart';

class NutritionService {
  NutritionPlan buildPlan({
    required MedicalResultModel result,
    required PlayerModel player,
    int? fatigue,
    int? age,
    double? weightKg,
  }) {
    final resolvedFatigue = fatigue ?? player.lastMatchFatigue ?? 40;
    final resolvedWeight = weightKg ?? 70;
    final severity = result.severity.trim().toLowerCase();
    final injuryType = result.injuryType.trim().toLowerCase();

    final baseCalories = (35 * resolvedWeight).round();
    final severityBoost = _severityBoost(severity);
    var calories = (baseCalories * (1 + severityBoost)).round();
    if (resolvedFatigue > 70) {
      calories += 200;
    }

    final proteinPerKg = _proteinPerKg(severity, result.injured);
    final carbsPerKg = _carbsPerKg(severity, resolvedFatigue);

    final proteinGrams = (resolvedWeight * proteinPerKg).round();
    final carbsGrams = (resolvedWeight * carbsPerKg).round();
    final fatGrams = _fatFromCalories(calories, proteinGrams, carbsGrams);

    final goal = _goalFor(result.injured, severity, resolvedFatigue);
    final meals = _buildMeals(injuryType, result.injured, resolvedFatigue);

    return NutritionPlan(
      goal: goal,
      calories: calories,
      proteinGrams: proteinGrams,
      carbsGrams: carbsGrams,
      fatGrams: fatGrams,
      meals: meals,
      tagline: 'Optimized for recovery',
    );
  }

  double _severityBoost(String severity) {
    if (severity.contains('severe')) {
      return 0.15;
    }
    if (severity.contains('moderate')) {
      return 0.10;
    }
    return 0.05;
  }

  double _proteinPerKg(String severity, bool injured) {
    if (!injured) {
      return 1.8;
    }
    if (severity.contains('severe')) {
      return 2.2;
    }
    if (severity.contains('moderate')) {
      return 2.0;
    }
    return 1.8;
  }

  double _carbsPerKg(String severity, int fatigue) {
    double carbs = 3.0;
    if (fatigue > 70) {
      carbs += 1.2;
    } else {
      carbs += 0.6;
    }
    if (severity.contains('severe')) {
      carbs += 0.6;
    } else if (severity.contains('moderate')) {
      carbs += 0.3;
    }
    if (carbs > 5.0) {
      carbs = 5.0;
    }
    return carbs;
  }

  int _fatFromCalories(int calories, int proteinGrams, int carbsGrams) {
    final proteinCalories = proteinGrams * 4;
    final carbsCalories = carbsGrams * 4;
    final remaining = calories - proteinCalories - carbsCalories;
    final fatGrams = remaining > 0 ? (remaining / 9).round() : 40;
    return fatGrams;
  }

  String _goalFor(bool injured, String severity, int fatigue) {
    if (injured) {
      return 'Recovery';
    }
    if (fatigue > 70) {
      return 'Performance';
    }
    if (severity.contains('moderate')) {
      return 'Prevention';
    }
    return 'Maintenance';
  }

  NutritionMeals _buildMeals(String injuryType, bool injured, int fatigue) {
    final breakfast = <String>[
      'Greek yogurt with berries',
      'Whole grain toast',
      'Boiled eggs',
    ];
    final lunch = <String>[
      'Grilled chicken bowl',
      'Quinoa or brown rice',
      'Mixed greens',
    ];
    final dinner = <String>[
      'Salmon or lean fish',
      'Roasted sweet potatoes',
      'Steamed vegetables',
    ];
    final hydration = <String>[
      '2.5-3L water',
      'Electrolyte mix',
      'Herbal recovery tea',
    ];

    if (injuryType.contains('knee') || injuryType.contains('ligament')) {
      lunch.add('Bone broth collagen');
      dinner.add('Turmeric + nuts');
      breakfast.add('Omega-3 eggs');
    }

    if (injuryType.contains('muscle') || injuryType.contains('fatigue')) {
      lunch.add('Pasta or rice');
      breakfast.add('Banana + spinach smoothie');
      hydration.add('Magnesium supplement');
    }

    if (injuryType.contains('ankle') || injuryType.contains('sprain')) {
      breakfast.add('Citrus + kiwi');
      lunch.add('Yogurt or kefir');
      dinner.add('Zinc-rich nuts');
    }

    if (fatigue > 70) {
      breakfast.add('Oats + honey');
      lunch.add('Extra complex carbs');
      hydration.add('Coconut water');
    }

    return NutritionMeals(
      breakfast: breakfast,
      lunch: lunch,
      dinner: dinner,
      hydration: hydration,
    );
  }
}
