import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/daily_log.dart';
import '../../data/models/meal.dart';
import '../../data/models/nutrition_target.dart';
import '../../providers/nutrition_log_provider.dart';

/// Dialog shown after workout completion to log post-workout nutrition
class PostWorkoutNutritionDialog extends ConsumerStatefulWidget {
  const PostWorkoutNutritionDialog({super.key});

  @override
  ConsumerState<PostWorkoutNutritionDialog> createState() =>
      _PostWorkoutNutritionDialogState();
}

class _PostWorkoutNutritionDialogState
    extends ConsumerState<PostWorkoutNutritionDialog> {
  String? _selectedMeal;
  bool _isLogging = false;

  // Common post-workout meals with quick-add functionality
  static const Map<String, Map<String, dynamic>> _commonMeals = {
    'Protein Shake (Whey)': {
      'calories': 120.0,
      'protein': 24.0,
      'carbs': 3.0,
      'fats': 1.5,
    },
    'Protein Shake + Banana': {
      'calories': 220.0,
      'protein': 25.0,
      'carbs': 30.0,
      'fats': 2.0,
    },
    'Greek Yogurt (200g)': {
      'calories': 130.0,
      'protein': 20.0,
      'carbs': 9.0,
      'fats': 0.5,
    },
    'Chocolate Milk (500ml)': {
      'calories': 315.0,
      'protein': 16.0,
      'carbs': 51.0,
      'fats': 5.0,
    },
    'Chicken Breast + Rice': {
      'calories': 400.0,
      'protein': 45.0,
      'carbs': 50.0,
      'fats': 5.0,
    },
  };

  Future<void> _logMeal() async {
    if (_selectedMeal == null) return;

    setState(() => _isLogging = true);

    try {
      final mealData = _commonMeals[_selectedMeal]!;
      
      final meal = MealEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        mealId: 'quick_add_${DateTime.now().millisecondsSinceEpoch}',
        mealName: _selectedMeal!,
        calories: mealData['calories'],
        macros: Macros(
          protein: mealData['protein'],
          carbs: mealData['carbs'],
          fats: mealData['fats'],
        ),
        timestamp: DateTime.now(),
        mealType: 'post_workout',
        servings: 1.0,
      );

      // Convert MealEntry to Meal for logMeal method
      final quickMeal = Meal(
        id: meal.mealId,
        name: meal.mealName,
        calories: meal.calories,
        macros: meal.macros,
        prepTimeMinutes: 5,
        difficulty: 'easy',
        ingredients: [],
        instructions: [],
        tags: ['post-workout'],
      );

      await ref.read(nutritionLogProvider.notifier).logMeal(quickMeal);

      if (mounted) {
        Navigator.of(context).pop(true); // Return true to indicate meal was logged
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to log meal: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      setState(() => _isLogging = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.local_drink,
                    color: AppColors.success,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Post-Workout Nutrition',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Fuel your recovery',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Info message
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryGold.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.primaryGold.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppColors.primaryGold,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Consuming protein within 30 minutes post-workout optimizes muscle recovery.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Meal selection
            Text(
              'Quick Add',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),

            // Meal options
            ..._commonMeals.entries.map((entry) {
              final isSelected = _selectedMeal == entry.key;
              final macros = entry.value;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: _isLogging
                      ? null
                      : () => setState(() => _selectedMeal = entry.key),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryGreen.withOpacity(0.1)
                          : AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primaryGreen
                            : AppColors.textSecondary.withOpacity(0.2),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                entry.key,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                Icons.check_circle,
                                color: AppColors.primaryGreen,
                                size: 24,
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 12,
                          children: [
                            _buildMacroChip(
                              '${macros['calories']} cal',
                              Icons.local_fire_department,
                            ),
                            _buildMacroChip(
                              '${macros['protein']}g P',
                              Icons.fitness_center,
                            ),
                            _buildMacroChip(
                              '${macros['carbs']}g C',
                              Icons.grain,
                            ),
                            _buildMacroChip(
                              '${macros['fats']}g F',
                              Icons.water_drop,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),

            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLogging
                        ? null
                        : () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Skip'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _selectedMeal == null || _isLogging
                        ? null
                        : _logMeal,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppColors.success,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLogging
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Log Meal',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroChip(String text, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ],
    );
  }
}
