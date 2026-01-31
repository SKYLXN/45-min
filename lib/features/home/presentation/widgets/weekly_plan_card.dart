import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../nutrition/providers/weekly_meal_plan_provider.dart';

/// Weekly Meal Plan Card for Home Screen
class WeeklyPlanCard extends ConsumerWidget {
  const WeeklyPlanCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(weeklyMealPlanProvider);
    final currentPlan = state.currentPlan;
    final isGenerating = state.isGenerating;

    return InkWell(
      onTap: () => context.push('/weekly-meal-plan'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: currentPlan != null
              ? LinearGradient(
                  colors: [
                    AppColors.primaryGreen.withOpacity(0.15),
                    AppColors.primaryGold.withOpacity(0.15),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : LinearGradient(
                  colors: [
                    AppColors.cardBackground,
                    AppColors.cardBackground,
                  ],
                ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: currentPlan != null
                ? AppColors.primaryGreen.withOpacity(0.3)
                : AppColors.textSecondary.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: isGenerating
            ? _buildLoadingState()
            : currentPlan != null
                ? _buildActivePlanState(context, currentPlan)
                : _buildEmptyState(context),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.calendar_month_rounded,
              color: AppColors.primaryGreen,
              size: 28,
            ),
            const SizedBox(width: 12),
            Text(
              'Generating Plan...',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        LinearProgressIndicator(
          backgroundColor: AppColors.textSecondary.withOpacity(0.2),
          valueColor: AlwaysStoppedAnimation(AppColors.primaryGreen),
        ),
        const SizedBox(height: 8),
        Text(
          'Creating your weekly meal plan...',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildActivePlanState(BuildContext context, dynamic currentPlan) {
    final startDate = currentPlan.startDate;
    final endDate = currentPlan.endDate;
    final totalMeals = currentPlan.totalMeals;
    final weeklyCalories = currentPlan.weeklyCalories.toInt();
    final avgDailyCalories = (weeklyCalories / 7).round();

    final dateFormat = DateFormat('MMM d');
    final dateRange = '${dateFormat.format(startDate)} - ${dateFormat.format(endDate)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.calendar_month_rounded,
                color: AppColors.primaryGreen,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Weekly Meal Plan',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    dateRange,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: AppColors.primaryGreen,
              size: 16,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Divider(
          color: AppColors.textSecondary.withOpacity(0.2),
          height: 1,
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(
              icon: Icons.restaurant_menu_rounded,
              label: 'Meals',
              value: '$totalMeals',
              color: AppColors.primaryGreen,
            ),
            _buildStatItem(
              icon: Icons.local_fire_department_rounded,
              label: 'Daily Avg',
              value: '${avgDailyCalories}kcal',
              color: AppColors.warning,
            ),
            _buildStatItem(
              icon: Icons.shopping_cart_rounded,
              label: 'Shopping',
              value: 'Ready',
              color: AppColors.primaryGold,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primaryGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.primaryGreen.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.check_circle_rounded,
                color: AppColors.primaryGreen,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Plan is active • Tap to view meals & shopping list',
                  style: TextStyle(
                    color: AppColors.primaryGreen,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.calendar_month_rounded,
              color: AppColors.textSecondary,
              size: 28,
            ),
            const SizedBox(width: 12),
            Text(
              'Weekly Meal Plan',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Plan your week with 2 meals per day',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildFeatureBadge(Icons.calendar_today, '7 Days'),
            const SizedBox(width: 8),
            _buildFeatureBadge(Icons.restaurant, '14 Meals'),
            const SizedBox(width: 8),
            _buildFeatureBadge(Icons.shopping_cart, 'Auto List'),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primaryGreen, AppColors.primaryGold],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_circle_outline,
                color: AppColors.backgroundDark,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Generate Weekly Plan',
                style: TextStyle(
                  color: AppColors.backgroundDark,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: color,
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.textSecondary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: AppColors.primaryGreen,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
