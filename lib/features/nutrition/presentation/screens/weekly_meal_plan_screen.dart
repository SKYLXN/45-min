import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../providers/weekly_meal_plan_provider.dart';
import '../../providers/dietary_profile_provider.dart';
import '../../data/models/weekly_meal_plan.dart';
import '../widgets/day_meal_card.dart';

class WeeklyMealPlanScreen extends ConsumerWidget {
  const WeeklyMealPlanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(weeklyMealPlanProvider);
    final currentPlan = state.currentPlan;

    // Show error if present
    if (state.error != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${state.error}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Dismiss',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      });
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        title: const Text('Weekly Meal Plan'),
        actions: [
          // Dietary restrictions indicator
          Consumer(
            builder: (context, ref, child) {
              final hasActiveRestrictions = ref.watch(hasActiveRestrictionsProvider);
              return IconButton(
                icon: Badge(
                  isLabelVisible: hasActiveRestrictions,
                  child: Icon(
                    hasActiveRestrictions ? Icons.filter_alt : Icons.filter_alt_off,
                    color: hasActiveRestrictions ? AppColors.primaryGreen : AppColors.textSecondary,
                  ),
                ),
                onPressed: () => context.push('/nutrition/dietary-restrictions'),
                tooltip: hasActiveRestrictions 
                    ? 'Dietary Restrictions Active' 
                    : 'Set Dietary Restrictions',
              );
            },
          ),
          if (currentPlan != null)
            IconButton(
              icon: const Icon(Icons.shopping_cart),
              onPressed: () {
                context.push('/shopping-list');
              },
            ),
        ],
      ),
      body: state.isGenerating
          ? _buildLoadingState()
          : currentPlan == null
              ? _buildEmptyState(context, ref)
              : _buildWeeklyPlan(context, ref, currentPlan),
      floatingActionButton: currentPlan == null
          ? FloatingActionButton.extended(
              onPressed: () => _generatePlan(ref),
              backgroundColor: AppColors.primaryGreen,
              icon: const Icon(Icons.auto_awesome, color: Colors.black),
              label: const Text(
                'Generate Plan',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : FloatingActionButton.extended(
              onPressed: () => _regeneratePlan(context, ref),
              backgroundColor: AppColors.primaryGold,
              icon: const Icon(Icons.refresh, color: Colors.black),
              label: const Text(
                'Regenerate',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              color: AppColors.primaryGreen,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Generating Your Weekly Plan...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Finding 14 delicious meals for the week',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant_menu,
              size: 80,
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'No Meal Plan Yet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Generate a weekly meal plan with 2 meals per day.\nGet automatic shopping lists and save time!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            _buildPlanFeatures(),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanFeatures() {
    return Column(
      children: [
        _buildFeatureItem(
          icon: Icons.calendar_today,
          title: '7 Days Planned',
          subtitle: '2 meals per day with variety',
        ),
        const SizedBox(height: 16),
        _buildFeatureItem(
          icon: Icons.shopping_basket,
          title: 'Auto Shopping List',
          subtitle: 'Export to Apple Reminders',
        ),
        const SizedBox(height: 16),
        Consumer(
          builder: (context, ref, child) {
            final hasActiveRestrictions = ref.watch(hasActiveRestrictionsProvider);
            final restrictionsCount = ref.watch(totalRestrictionsCountProvider);
            
            return _buildFeatureItem(
              icon: hasActiveRestrictions ? Icons.filter_alt : Icons.filter_alt_off,
              title: hasActiveRestrictions 
                  ? 'Dietary Restrictions ($restrictionsCount)' 
                  : 'No Dietary Restrictions',
              subtitle: hasActiveRestrictions 
                  ? 'Meals filtered for your needs' 
                  : 'Tap filter icon to set restrictions',
              isWarning: !hasActiveRestrictions,
            );
          },
        ),
      ],
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String subtitle,
    bool isWarning = false,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon, 
            color: isWarning ? AppColors.textSecondary : AppColors.primaryGreen, 
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWeeklyPlan(
    BuildContext context,
    WidgetRef ref,
    WeeklyMealPlan plan,
  ) {
    final dates = plan.getAllDates();

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _buildPlanHeader(context, ref, plan),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final date = dates[index];
              final dayPlan = plan.getMealPlanForDay(date);
              
              if (dayPlan == null) return const SizedBox.shrink();

              return DayMealCard(
                date: date,
                dayPlan: dayPlan,
                onSwapMeal: (mealIndex) {
                  ref
                      .read(weeklyMealPlanProvider.notifier)
                      .swapMeal(date, mealIndex);
                },
              );
            },
            childCount: dates.length,
          ),
        ),
        const SliverToBoxAdapter(
          child: SizedBox(height: 100), // Space for FAB
        ),
      ],
    );
  }

  Widget _buildPlanHeader(
    BuildContext context,
    WidgetRef ref,
    WeeklyMealPlan plan,
  ) {
    final dateFormat = DateFormat('MMM d');
    final startStr = dateFormat.format(plan.startDate);
    final endStr = dateFormat.format(plan.endDate);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryGreen, AppColors.primaryGold],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'This Week\'s Plan',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$startStr - $endStr',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${plan.totalMeals} meals',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatChip(
                '${plan.averageDailyCalories.round()} cal/day',
                Icons.local_fire_department,
              ),
              const SizedBox(width: 8),
              _buildStatChip(
                '${plan.averageDailyProtein.round()}g protein/day',
                Icons.fitness_center,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black12,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.black87),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _generatePlan(WidgetRef ref) async {
    await ref.read(weeklyMealPlanProvider.notifier).generateWeeklyPlan();
  }

  Future<void> _regeneratePlan(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: Text(
          'Regenerate Plan?',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          'This will create a new meal plan for the week. Your current plan will be saved in history.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGold,
            ),
            child: const Text(
              'Regenerate',
              style: TextStyle(color: Colors.black),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(weeklyMealPlanProvider.notifier).generateWeeklyPlan();
    }
  }
}
