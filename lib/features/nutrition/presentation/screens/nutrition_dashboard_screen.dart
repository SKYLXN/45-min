import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../providers/nutrition_target_provider.dart';
import '../../providers/nutrition_log_provider.dart';
import '../widgets/calorie_counter.dart';
import '../widgets/macro_ring_chart.dart';
import '../widgets/meal_log_item.dart';
import '../widgets/nutrition_target_card.dart';

/// Nutrition Dashboard Screen - Main nutrition tracking hub
class NutritionDashboardScreen extends ConsumerWidget {
  const NutritionDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final targetState = ref.watch(nutritionTargetProvider);
    final logState = ref.watch(nutritionLogProvider);
    final caloriesConsumed = ref.watch(caloriesConsumedProvider);
    final macrosConsumed = ref.watch(macrosConsumedProvider);
    final todayMeals = ref.watch(todayMealsProvider);
    final isWorkoutDay = ref.watch(isWorkoutDayProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        title: const Text('Nutrition'),
        backgroundColor: AppColors.cardBackground,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/nutrition/dietary-restrictions'),
            tooltip: 'Dietary Restrictions',
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today_outlined),
            onPressed: () => context.push('/nutrition/meal-plan'),
            tooltip: 'Meal Plan',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(nutritionTargetProvider.notifier).refresh();
          await ref.read(nutritionLogProvider.notifier).loadTodayLog();
        },
        child: targetState.isLoading
            ? const Center(child: CircularProgressIndicator())
            : targetState.error != null
                ? _buildErrorState(context, targetState.error!, ref)
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Workout day banner
                      if (isWorkoutDay.whenOrNull(data: (data) => data) ?? false)
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primaryGreen.withOpacity(0.2),
                                AppColors.warning.withOpacity(0.2),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.primaryGreen.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.fitness_center,
                                color: AppColors.primaryGreen,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Workout Day 💪',
                                      style: TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'Extra calories added for training',
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Calorie Counter
                      CalorieCounter(
                        targetCalories: targetState.target?.dailyCalories ?? 0,
                        consumedCalories: caloriesConsumed,
                        isWorkoutDay: isWorkoutDay.whenOrNull(data: (data) => data) ?? false,
                      ),

                      const SizedBox(height: 24),

                      // Macro Ring Chart
                      MacroRingChart(
                        targetProtein: targetState.target?.macros.protein ?? 0,
                        targetCarbs: targetState.target?.macros.carbs ?? 0,
                        targetFats: targetState.target?.macros.fats ?? 0,
                        consumedProtein: (macrosConsumed['protein'] ?? 0).toDouble(),
                        consumedCarbs: (macrosConsumed['carbs'] ?? 0).toDouble(),
                        consumedFats: (macrosConsumed['fats'] ?? 0).toDouble(),
                      ),

                      const SizedBox(height: 24),

                      // Nutrition Target Card
                      NutritionTargetCard(
                        target: targetState.target,
                        lastCalculated: targetState.lastCalculated,
                        onRecalculate: () =>
                            ref.read(nutritionTargetProvider.notifier).refresh(),
                      ),

                      const SizedBox(height: 24),

                      // Today's Meals Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Today\'s Meals',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () => context.push('/recipe-search'),
                            icon: const Icon(Icons.add),
                            label: const Text('Add Meal'),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Meal logs
                      if (logState.isLoading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (todayMeals.isEmpty)
                        _buildEmptyMealsState(context)
                      else
                        ...todayMeals.map((meal) => MealLogItem(
                              meal: meal,
                              onDelete: () => ref
                                  .read(nutritionLogProvider.notifier)
                                  .removeMeal(meal.id),
                            )),

                      const SizedBox(height: 24),

                      // Quick Actions
                      _buildQuickActions(context),

                      const SizedBox(height: 16),
                    ],
                  ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/nutrition/suggestions'),
        icon: const Icon(Icons.lightbulb_outline),
        label: const Text('Meal Ideas'),
        backgroundColor: AppColors.primaryGreen,
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error.withOpacity(0.7),
            ),
            const SizedBox(height: 16),
            Text(
              'Unable to load nutrition data',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                ref.read(nutritionTargetProvider.notifier).refresh();
                ref.read(nutritionLogProvider.notifier).loadTodayLog();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyMealsState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.textSecondary.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.restaurant_menu_outlined,
            size: 48,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 12),
          Text(
            'No meals logged yet',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start tracking your meals to monitor your nutrition',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => context.push('/recipe-search'),
            icon: const Icon(Icons.add),
            label: const Text('Log Your First Meal'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                context,
                icon: Icons.search,
                label: 'Recipe Search',
                onTap: () => context.push('/recipe-search'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                context,
                icon: Icons.calendar_today,
                label: 'Meal Plan',
                onTap: () => context.push('/nutrition/meal-plan'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.textSecondary.withOpacity(0.2),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: AppColors.primaryGreen,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
