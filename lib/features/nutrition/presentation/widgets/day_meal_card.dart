import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/weekly_meal_plan.dart';

class DayMealCard extends StatelessWidget {
  final DateTime date;
  final DayMealPlan dayPlan;
  final Function(int mealIndex) onSwapMeal;

  const DayMealCard({
    super.key,
    required this.date,
    required this.dayPlan,
    required this.onSwapMeal,
  });

  @override
  Widget build(BuildContext context) {
    final dayName = DateFormat('EEEE').format(date);
    final dateStr = DateFormat('MMM d').format(date);
    final isToday = _isToday(date);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: isToday
            ? Border.all(color: AppColors.primaryGreen, width: 2)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isToday
                  ? AppColors.primaryGreen.withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    if (isToday)
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'TODAY',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dayName,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          dateStr,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                _buildTotalMacros(),
              ],
            ),
          ),

          // Meal 1
          _buildMealItem(
            context,
            meal: dayPlan.meal1,
            label: 'Meal 1',
            mealIndex: 0,
          ),

          Divider(
            height: 1,
            thickness: 1,
            color: AppColors.textSecondary.withOpacity(0.1),
          ),

          // Meal 2
          _buildMealItem(
            context,
            meal: dayPlan.meal2,
            label: 'Meal 2',
            mealIndex: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildTotalMacros() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.backgroundDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${dayPlan.totalCalories} cal',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            'P:${dayPlan.totalProtein.round()}g C:${dayPlan.totalCarbs.round()}g F:${dayPlan.totalFat.round()}g',
            style: TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealItem(
    BuildContext context, {
    required meal,
    required String label,
    required int mealIndex,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Meal image
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: meal.imageUrl != null
                ? CachedNetworkImage(
                    imageUrl: meal.imageUrl!,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      width: 80,
                      height: 80,
                      color: AppColors.backgroundDark,
                      child: Icon(
                        Icons.restaurant,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: 80,
                      height: 80,
                      color: AppColors.backgroundDark,
                      child: Icon(
                        Icons.restaurant,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  )
                : Container(
                    width: 80,
                    height: 80,
                    color: AppColors.backgroundDark,
                    child: Icon(
                      Icons.restaurant,
                      color: AppColors.textSecondary,
                    ),
                  ),
          ),
          const SizedBox(width: 16),

          // Meal info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  meal.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildMacroChip(
                      '${meal.calories} cal',
                      Icons.local_fire_department,
                      Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    _buildMacroChip(
                      '${meal.prepTimeMinutes} min',
                      Icons.timer,
                      AppColors.primaryGold,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Swap button
          IconButton(
            onPressed: () => onSwapMeal(mealIndex),
            icon: Icon(
              Icons.swap_horiz,
              color: AppColors.primaryGreen,
            ),
            tooltip: 'Swap meal',
          ),
        ],
      ),
    );
  }

  Widget _buildMacroChip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}
