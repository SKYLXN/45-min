import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/daily_log.dart';

/// Meal Log Item - Display a logged meal with macros and actions
class MealLogItem extends StatelessWidget {
  final MealEntry meal;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  const MealLogItem({
    super.key,
    required this.meal,
    this.onDelete,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final timeFormatter = DateFormat('h:mm a');
    final mealTime = meal.timestamp != null
        ? timeFormatter.format(meal.timestamp!)
        : 'Not logged';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.textSecondary.withOpacity(0.2),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onEdit,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Meal icon
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primaryGreen.withOpacity(0.3),
                            AppColors.primaryGreen.withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _getMealIcon(meal.mealName),
                        color: AppColors.primaryGreen,
                        size: 24,
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Meal info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            meal.mealName,
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 14,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                mealTime,
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '${meal.calories} kcal',
                                style: TextStyle(
                                  color: AppColors.primaryGreen,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Delete button
                    if (onDelete != null)
                      IconButton(
                        icon: Icon(
                          Icons.delete_outline,
                          color: AppColors.error.withOpacity(0.7),
                          size: 20,
                        ),
                        onPressed: () => _showDeleteConfirmation(context),
                        tooltip: 'Delete meal',
                      ),
                  ],
                ),

                const SizedBox(height: 12),

                // Macros
                Row(
                  children: [
                    _buildMacroChip(
                      label: 'P',
                      value: '${meal.macros.protein.toInt()}g',
                      color: AppColors.primaryGreen,
                    ),
                    const SizedBox(width: 8),
                    _buildMacroChip(
                      label: 'C',
                      value: '${meal.macros.carbs.toInt()}g',
                      color: AppColors.primaryGold,
                    ),
                    const SizedBox(width: 8),
                    _buildMacroChip(
                      label: 'F',
                      value: '${meal.macros.fats.toInt()}g',
                      color: AppColors.warning,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMacroChip({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getMealIcon(String mealName) {
    final lowerName = mealName.toLowerCase();
    if (lowerName.contains('breakfast')) return Icons.free_breakfast;
    if (lowerName.contains('lunch')) return Icons.lunch_dining;
    if (lowerName.contains('dinner')) return Icons.dinner_dining;
    if (lowerName.contains('snack')) return Icons.cookie;
    return Icons.restaurant;
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: Text(
          'Delete Meal?',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          'Remove "${meal.mealName}" from today\'s log?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete?.call();
            },
            child: Text(
              'Delete',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
