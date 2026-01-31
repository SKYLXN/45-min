import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../providers/meal_plan_provider.dart';
import '../../providers/nutrition_target_provider.dart';
import '../../providers/nutrition_log_provider.dart';

class MealPlanGeneratorScreen extends ConsumerWidget {
  const MealPlanGeneratorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planState = ref.watch(mealPlanProvider);
    final target = ref.watch(dailyNutritionTargetProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text('Meal Plan Generator'),
        backgroundColor: AppColors.cardBackground,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (target != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryGreen.withOpacity(0.2),
                    AppColors.primaryGreen.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    'Daily Target',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${target!.dailyCalories} kcal',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: planState.isGenerating
                ? null
                : () async {
                    await ref.read(mealPlanProvider.notifier).generateDailyPlan();
                  },
            icon: planState.isGenerating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome),
            label: Text(planState.isGenerating ? 'Generating...' : 'Generate Meal Plan'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              padding: const EdgeInsets.all(16),
            ),
          ),
          if (planState.currentPlan != null) ...[
            const SizedBox(height: 24),
            Text(
              'Today\'s Plan',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...planState.currentPlan!.meals.map((meal) => Card(
                  color: AppColors.cardBackground,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: Icon(Icons.restaurant, color: AppColors.primaryGreen),
                    title: Text(
                      meal.name,
                      style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          '${meal.calories} kcal • ${meal.macros.protein.toInt()}g protein',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '⏱️ ${meal.prepTimeMinutes} min • ${meal.difficulty}',
                          style: TextStyle(color: AppColors.textSecondary.withOpacity(0.7), fontSize: 12),
                        ),
                      ],
                    ),
                    isThreeLine: true,
                    trailing: IconButton(
                      icon: Icon(Icons.add_circle_outline, color: AppColors.primaryGreen),
                      onPressed: () async {
                        // Add to today's log
                        await ref.read(nutritionLogProvider.notifier).logMeal(meal);
                        
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${meal.name} added to today\'s log'),
                              backgroundColor: AppColors.primaryGreen,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      tooltip: 'Add to Log',
                    ),
                    onTap: () {
                      // Navigate to recipe detail if available
                      if (meal.id.isNotEmpty) {
                        context.push('/recipe-detail/${meal.id}');
                      }
                    },
                  ),
                )),
          ],
        ],
      ),
    );
  }

  String _getMealTypeFromTime() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'breakfast';
    if (hour < 15) return 'lunch';
    if (hour < 18) return 'snack';
    return 'dinner';
  }
}
