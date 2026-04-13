import 'package:flutter/material.dart';

import '../models/nutrition_model.dart';
import '../theme/app_theme.dart';

class NutritionCard extends StatelessWidget {
  const NutritionCard({super.key, required this.plan});

  final NutritionPlan plan;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 8 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF0B1A2B),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.cardBorder),
          boxShadow: [
            BoxShadow(
              color: AppTheme.accentBlue.withOpacity(0.25),
              blurRadius: 24,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Nutrition Goal: ${plan.goal}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ) ??
                        const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                const SizedBox(width: 8),
                _TagChip(text: plan.tagline),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Daily Calories: ${plan.calories} kcal',
              style:
                  textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                  ) ??
                  const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _MacroTile(label: 'Protein', value: '${plan.proteinGrams}g'),
                const SizedBox(width: 12),
                _MacroTile(label: 'Carbs', value: '${plan.carbsGrams}g'),
                const SizedBox(width: 12),
                _MacroTile(label: 'Fat', value: '${plan.fatGrams}g'),
              ],
            ),
            const SizedBox(height: 16),
            _MealSection(
              title: 'Breakfast',
              icon: Icons.breakfast_dining,
              items: plan.meals.breakfast,
            ),
            const SizedBox(height: 12),
            _MealSection(
              title: 'Lunch',
              icon: Icons.lunch_dining,
              items: plan.meals.lunch,
            ),
            const SizedBox(height: 12),
            _MealSection(
              title: 'Dinner',
              icon: Icons.dinner_dining,
              items: plan.meals.dinner,
            ),
            const SizedBox(height: 12),
            _MealSection(
              title: 'Hydration',
              icon: Icons.water_drop,
              items: plan.meals.hydration,
            ),
          ],
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.accentBlue.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _MacroTile extends StatelessWidget {
  const _MacroTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.surfaceAlt,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style:
                  textTheme.labelMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ) ??
                  const TextStyle(fontSize: 11),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style:
                  textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700) ??
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _MealSection extends StatelessWidget {
  const _MealSection({
    required this.title,
    required this.icon,
    required this.items,
  });

  final String title;
  final IconData icon;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: AppTheme.accentBlue),
            const SizedBox(width: 8),
            Text(
              title,
              style:
                  textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600) ??
                  const TextStyle(fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              '- $item',
              style:
                  textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ) ??
                  const TextStyle(fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }
}
