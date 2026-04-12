class NutritionPlan {
  const NutritionPlan({
    required this.goal,
    required this.calories,
    required this.proteinGrams,
    required this.carbsGrams,
    required this.fatGrams,
    required this.meals,
    required this.tagline,
  });

  final String goal;
  final int calories;
  final int proteinGrams;
  final int carbsGrams;
  final int fatGrams;
  final NutritionMeals meals;
  final String tagline;
}

class NutritionMeals {
  const NutritionMeals({
    required this.breakfast,
    required this.lunch,
    required this.dinner,
    required this.hydration,
  });

  final List<String> breakfast;
  final List<String> lunch;
  final List<String> dinner;
  final List<String> hydration;
}
