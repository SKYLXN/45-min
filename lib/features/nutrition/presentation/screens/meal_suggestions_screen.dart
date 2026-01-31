import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../providers/nutrition_target_provider.dart';

class MealSuggestionsScreen extends ConsumerWidget {
  const MealSuggestionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postWorkout = ref.watch(postWorkoutMealProvider);
    final preWorkout = ref.watch(preWorkoutMealProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text('Meal Suggestions'),
        backgroundColor: AppColors.cardBackground,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Smart Meal Ideas',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (postWorkout.hasValue && postWorkout.value != null)
            _buildMealCard(
              context,
              title: 'Post-Workout Meal',
              description: 'High protein & carbs to aid recovery',
              icon: Icons.fitness_center,
              color: AppColors.primaryGreen,
              onTap: () => context.push('/recipe-search'),
            ),
          if (preWorkout.hasValue && preWorkout.value != null)
            _buildMealCard(
              context,
              title: 'Pre-Workout Snack',
              description: 'Quick energy boost before training',
              icon: Icons.bolt,
              color: AppColors.warning,
              onTap: () => context.push('/recipe-search'),
            ),
          _buildMealCard(
            context,
            title: 'High Protein Meals',
            description: 'Build and maintain muscle mass',
            icon: Icons.egg,
            color: AppColors.primaryGreen,
            onTap: () => context.push('/recipe-search'),
          ),
          _buildMealCard(
            context,
            title: 'Quick & Easy',
            description: 'Ready in 30 minutes or less',
            icon: Icons.speed,
            color: AppColors.primaryGold,
            onTap: () => context.push('/recipe-search'),
          ),
        ],
      ),
    );
  }

  Widget _buildMealCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      color: AppColors.cardBackground,
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: AppColors.textSecondary, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
