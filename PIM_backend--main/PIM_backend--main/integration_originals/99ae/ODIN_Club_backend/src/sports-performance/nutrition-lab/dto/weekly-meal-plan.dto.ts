export class MealPlanDto {
  name: string;
  kcal: number;
  carbs: number;
  proteins: number;
  fats: number;
  description: string;
  icon: string;
}

export class DailyMealPlanDto {
  day: string;
  totalKcal: number;
  meals: MealPlanDto[];
  advice: string;
}

export class WeeklyMealPlanDto {
  userId: string;
  weekNumber: number;
  days: DailyMealPlanDto[];
}
