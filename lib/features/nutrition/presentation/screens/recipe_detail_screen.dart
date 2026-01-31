import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../providers/recipe_search_provider.dart';
import '../../providers/nutrition_log_provider.dart';
import '../../data/models/meal.dart';
import '../../data/models/nutrition_target.dart';

/// Recipe Detail Screen - Full recipe details with nutritional breakdown
class RecipeDetailScreen extends ConsumerStatefulWidget {
  final String recipeId;

  const RecipeDetailScreen({
    super.key,
    required this.recipeId,
  });

  @override
  ConsumerState<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends ConsumerState<RecipeDetailScreen> {
  double _servingMultiplier = 1.0;

  @override
  Widget build(BuildContext context) {
    final recipeAsync = ref.watch(recipeDetailProvider(widget.recipeId));

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: recipeAsync.when(
        data: (recipe) => CustomScrollView(
          slivers: [
            // App Bar with Image
            SliverAppBar(
              expandedHeight: 300,
              pinned: true,
              backgroundColor: AppColors.cardBackground,
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (recipe?.imageUrl != null)
                      CachedNetworkImage(
                        imageUrl: recipe!.imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: AppColors.backgroundDark,
                        ),
                        errorWidget: (context, url, error) => _buildImagePlaceholder(),
                      )
                    else
                      _buildImagePlaceholder(),

                    // Gradient overlay
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            AppColors.backgroundDark.withOpacity(0.7),
                            AppColors.backgroundDark,
                          ],
                          stops: const [0.0, 0.7, 1.0],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      recipe?.name ?? 'Recipe',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Quick stats
                    Row(
                      children: [
                        _buildStatChip(
                          icon: Icons.access_time,
                          label: '${recipe?.prepTime ?? 0} min',
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 12),
                        _buildStatChip(
                          icon: Icons.restaurant,
                          label: '${recipe?.servings ?? 1} servings',
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 12),
                        _buildStatChip(
                          icon: Icons.local_fire_department,
                          label: '${((recipe?.macros.totalCalories ?? 0) * _servingMultiplier).toInt()} kcal',
                          color: AppColors.warning,
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Serving size adjuster
                    _buildServingAdjuster(),

                    const SizedBox(height: 24),

                    // Nutrition breakdown
                    if (recipe?.macros != null)
                      _buildNutritionCard(recipe!.macros),

                    const SizedBox(height: 24),

                    // Ingredients
                    Text(
                      'Ingredients',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...(recipe?.ingredients ?? []).map((ingredient) => _buildIngredientItem(
                          ingredient.name,
                          ingredient.amount * _servingMultiplier,
                          ingredient.unit,
                        )),

                    const SizedBox(height: 24),

                    // Instructions
                    if (recipe?.instructions.isNotEmpty ?? false) ...[
                      Text(
                        'Instructions',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...(recipe?.instructions ?? []).asMap().entries.map((entry) =>
                          _buildInstructionStep(entry.key + 1, entry.value)),
                    ],

                    const SizedBox(height: 80), // Space for FAB
                  ],
                ),
              ),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
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
                  'Unable to load recipe',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => ref.refresh(recipeDetailProvider(widget.recipeId)),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: recipeAsync.whenOrNull(
        data: (recipe) => FloatingActionButton.extended(
          onPressed: () => _addToLog(recipe),
          icon: const Icon(Icons.add),
          label: const Text('Add to Log'),
          backgroundColor: AppColors.primaryGreen,
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: AppColors.backgroundDark,
      child: Center(
        child: Icon(
          Icons.restaurant_menu,
          size: 80,
          color: AppColors.textSecondary.withOpacity(0.3),
        ),
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServingAdjuster() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.textSecondary.withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Serving Size',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: _servingMultiplier > 0.5
                    ? () => setState(() => _servingMultiplier -= 0.5)
                    : null,
                icon: const Icon(Icons.remove_circle_outline),
                color: AppColors.primaryGreen,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.backgroundDark,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '×${_servingMultiplier.toStringAsFixed(1)}',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: _servingMultiplier < 5.0
                    ? () => setState(() => _servingMultiplier += 0.5)
                    : null,
                icon: const Icon(Icons.add_circle_outline),
                color: AppColors.primaryGreen,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionCard(Macros nutrition) {
    final adjustedNutrition = Macros(
      protein: nutrition.protein * _servingMultiplier,
      carbs: nutrition.carbs * _servingMultiplier,
      fats: nutrition.fats * _servingMultiplier,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.textSecondary.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nutrition (per serving)',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNutrientColumn(
                'Protein',
                adjustedNutrition.protein,
                'g',
                AppColors.primaryGreen,
              ),
              _buildNutrientColumn(
                'Carbs',
                adjustedNutrition.carbs,
                'g',
                AppColors.primaryGold,
              ),
              _buildNutrientColumn(
                'Fats',
                adjustedNutrition.fats,
                'g',
                AppColors.warning,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNutrientColumn(String label, double value, String unit, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${value.toInt()}$unit',
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildIngredientItem(String name, double amount, String unit) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: AppColors.primaryGreen,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
              ),
            ),
          ),
          Text(
            '${amount.toStringAsFixed(1)} $unit',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionStep(int step, String instruction) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primaryGreen,
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                step.toString(),
                style: TextStyle(
                  color: AppColors.primaryGreen,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              instruction,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addToLog(dynamic recipe) async {
    final meal = Meal(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: recipe.name,
      imageUrl: recipe.imageUrl,
      calories: (recipe.macros.totalCalories * _servingMultiplier).toInt(),
      macros: Macros(
        protein: recipe.macros.protein * _servingMultiplier,
        carbs: recipe.macros.carbs * _servingMultiplier,
        fats: recipe.macros.fats * _servingMultiplier,
      ),
      prepTimeMinutes: recipe.prepTime,
      difficulty: 'medium',
      ingredients: recipe.ingredients,
      instructions: recipe.instructions,
      recipeUrl: recipe.recipeUrl,
      tags: [],
    );

    try {
      await ref.read(nutritionLogProvider.notifier).logMeal(meal);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added to today\'s log'),
            backgroundColor: AppColors.primaryGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add meal: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
