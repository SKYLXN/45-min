import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/user_profile_provider.dart';
import '../data/models/daily_meal_plan.dart';
import '../data/services/spoonacular_api_service.dart';
import 'nutrition_target_provider.dart';
import 'recipe_search_provider.dart';

// ============================================================================
// State Management
// ============================================================================

/// State for meal plan generation and management
class MealPlanState {
  final DailyMealPlan? currentPlan;
  final Map<DateTime, DailyMealPlan> savedPlans; // Cache of generated plans
  final bool isGenerating;
  final String? error;
  final DateTime? lastGenerated;

  const MealPlanState({
    this.currentPlan,
    this.savedPlans = const {},
    this.isGenerating = false,
    this.error,
    this.lastGenerated,
  });

  MealPlanState copyWith({
    DailyMealPlan? currentPlan,
    Map<DateTime, DailyMealPlan>? savedPlans,
    bool? isGenerating,
    String? error,
    DateTime? lastGenerated,
  }) {
    return MealPlanState(
      currentPlan: currentPlan ?? this.currentPlan,
      savedPlans: savedPlans ?? this.savedPlans,
      isGenerating: isGenerating ?? this.isGenerating,
      error: error,
      lastGenerated: lastGenerated ?? this.lastGenerated,
    );
  }
}

/// Notifier for meal plan management
class MealPlanNotifier extends StateNotifier<MealPlanState> {
  MealPlanNotifier(this._ref) : super(const MealPlanState());

  final Ref _ref;

  /// Generate daily meal plan based on nutrition target
  Future<void> generateDailyPlan({DateTime? date}) async {
    try {
      final targetDate = date ?? DateTime.now();
      
      state = state.copyWith(isGenerating: true, error: null);

      // Get nutrition target
      final targetState = _ref.read(nutritionTargetProvider);
      if (targetState.target == null) {
        await _ref.read(nutritionTargetProvider.notifier).calculateTodayTarget();
      }

      final target = _ref.read(nutritionTargetProvider).target;
      if (target == null) {
        throw Exception('Unable to calculate nutrition target');
      }

      // Get user's dietary restrictions
      final userProfile = await _ref.read(userProfileProvider.future);
      if (userProfile == null) {
        throw Exception('User profile not found');
      }

      // Generate meal plan using API
      final apiService = _ref.read(spoonacularApiServiceProvider);
      final mealPlan = await apiService.generateMealPlan(
        targetCalories: target.dailyCalories,
        diet: userProfile.spoonacularDiet,
        excludeIngredients: userProfile.excludedIngredients,
        intolerances: userProfile.spoonacularIntolerances,
      );

      // Update state with generated plan
      final updatedPlans = Map<DateTime, DailyMealPlan>.from(state.savedPlans);
      final dateKey = DateTime(targetDate.year, targetDate.month, targetDate.day);
      updatedPlans[dateKey] = mealPlan;

      state = state.copyWith(
        currentPlan: mealPlan,
        savedPlans: updatedPlans,
        isGenerating: false,
        lastGenerated: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(
        isGenerating: false,
        error: e.toString(),
      );
    }
  }

  /// Generate weekly meal plan (7 days)
  Future<void> generateWeeklyPlan({DateTime? startDate}) async {
    try {
      final start = startDate ?? DateTime.now();
      
      state = state.copyWith(isGenerating: true, error: null);

      // Get nutrition target
      final targetState = _ref.read(nutritionTargetProvider);
      if (targetState.target == null) {
        await _ref.read(nutritionTargetProvider.notifier).calculateTodayTarget();
      }

      final target = _ref.read(nutritionTargetProvider).target;
      if (target == null) {
        throw Exception('Unable to calculate nutrition target');
      }

      // Get user's dietary restrictions
      final userProfile = await _ref.read(userProfileProvider.future);
      if (userProfile == null) {
        throw Exception('User profile not found');
      }

      final apiService = _ref.read(spoonacularApiServiceProvider);
      final updatedPlans = Map<DateTime, DailyMealPlan>.from(state.savedPlans);

      // Generate plan for each day
      for (int i = 0; i < 7; i++) {
        final date = start.add(Duration(days: i));
        final dateKey = DateTime(date.year, date.month, date.day);

        // Skip if plan already exists for this date
        if (updatedPlans.containsKey(dateKey)) {
          continue;
        }

        final mealPlan = await apiService.generateMealPlan(
          targetCalories: target.dailyCalories,
          diet: userProfile.spoonacularDiet,
          excludeIngredients: userProfile.excludedIngredients,
          intolerances: userProfile.spoonacularIntolerances,
        );

        updatedPlans[dateKey] = mealPlan;

        // Small delay to avoid rate limiting
        await Future.delayed(const Duration(milliseconds: 500));
      }

      state = state.copyWith(
        currentPlan: updatedPlans[DateTime(start.year, start.month, start.day)],
        savedPlans: updatedPlans,
        isGenerating: false,
        lastGenerated: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(
        isGenerating: false,
        error: e.toString(),
      );
    }
  }

  /// Get meal plan for specific date
  DailyMealPlan? getPlanForDate(DateTime date) {
    final dateKey = DateTime(date.year, date.month, date.day);
    return state.savedPlans[dateKey];
  }

  /// Load saved plan for specific date
  Future<void> loadPlanForDate(DateTime date) async {
    final dateKey = DateTime(date.year, date.month, date.day);
    final plan = state.savedPlans[dateKey];

    if (plan != null) {
      state = state.copyWith(currentPlan: plan);
    } else {
      // Generate new plan if not found
      await generateDailyPlan(date: date);
    }
  }

  /// Swap a single meal in the plan
  Future<void> swapMeal({
    required int mealIndex,
    DateTime? date,
  }) async {
    try {
      final targetDate = date ?? DateTime.now();
      final dateKey = DateTime(targetDate.year, targetDate.month, targetDate.day);
      
      final currentPlan = state.savedPlans[dateKey] ?? state.currentPlan;
      if (currentPlan == null) {
        throw Exception('No meal plan found for this date');
      }

      if (mealIndex < 0 || mealIndex >= currentPlan.meals.length) {
        throw Exception('Invalid meal index');
      }

      state = state.copyWith(isGenerating: true, error: null);

      final oldMeal = currentPlan.meals[mealIndex];

      // Get user's dietary restrictions
      final userProfile = await _ref.read(userProfileProvider.future);
      if (userProfile == null) {
        throw Exception('User profile not found');
      }

      // Search for similar meal with similar calories
      final apiService = _ref.read(spoonacularApiServiceProvider);
      final similarMeals = await apiService.searchRecipes(
        maxCalories: (oldMeal.calories * 1.2).round(), // ±20% calories
        minProtein: (oldMeal.macros.protein * 0.8).round(),
        excludeIngredients: userProfile.excludedIngredients,
        diet: userProfile.spoonacularDiet,
        intolerances: userProfile.spoonacularIntolerances,
        number: 5,
      );

      if (similarMeals.isEmpty) {
        throw Exception('No alternative meals found');
      }

      // Pick the first alternative
      final newMeal = similarMeals.first;

      // Update meal plan with new meal
      final updatedMeals = List.of(currentPlan.meals);
      updatedMeals[mealIndex] = newMeal;

      final updatedPlan = DailyMealPlan(
        date: currentPlan.date,
        meals: updatedMeals,
        totalCalories: updatedMeals.fold(0, (sum, meal) => sum + meal.calories),
        totalProtein: updatedMeals.fold(0, (sum, meal) => sum + meal.macros.protein.round()),
        totalCarbs: updatedMeals.fold(0, (sum, meal) => sum + meal.macros.carbs.round()),
        totalFat: updatedMeals.fold(0, (sum, meal) => sum + meal.macros.fats.round()),
      );

      final updatedPlans = Map<DateTime, DailyMealPlan>.from(state.savedPlans);
      updatedPlans[dateKey] = updatedPlan;

      state = state.copyWith(
        currentPlan: updatedPlan,
        savedPlans: updatedPlans,
        isGenerating: false,
      );
    } catch (e) {
      state = state.copyWith(
        isGenerating: false,
        error: e.toString(),
      );
    }
  }

  /// Clear all saved plans
  void clearPlans() {
    state = state.copyWith(
      currentPlan: null,
      savedPlans: {},
    );
  }

  /// Clear error state
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Regenerate current plan
  Future<void> regeneratePlan() async {
    if (state.currentPlan != null) {
      await generateDailyPlan(date: state.currentPlan!.date);
    } else {
      await generateDailyPlan();
    }
  }
}

// ============================================================================
// Providers
// ============================================================================

/// Main provider for meal plan state
final mealPlanProvider =
    StateNotifierProvider<MealPlanNotifier, MealPlanState>((ref) {
  return MealPlanNotifier(ref);
});

/// Provider for today's meal plan
final todayMealPlanProvider = Provider<DailyMealPlan?>((ref) {
  final state = ref.watch(mealPlanProvider);
  final today = DateTime.now();
  final dateKey = DateTime(today.year, today.month, today.day);
  
  return state.savedPlans[dateKey] ?? state.currentPlan;
});

/// Provider for meal plan for specific date
final mealPlanForDateProvider =
    Provider.family<DailyMealPlan?, DateTime>((ref, date) {
  final state = ref.watch(mealPlanProvider);
  final dateKey = DateTime(date.year, date.month, date.day);
  
  return state.savedPlans[dateKey];
});

/// Provider to check if meal plan exists for today
final hasTodayMealPlanProvider = Provider<bool>((ref) {
  final plan = ref.watch(todayMealPlanProvider);
  return plan != null;
});

/// Provider for meal plan generation status
final isMealPlanGeneratingProvider = Provider<bool>((ref) {
  final state = ref.watch(mealPlanProvider);
  return state.isGenerating;
});

/// Provider for number of saved plans
final savedPlansCountProvider = Provider<int>((ref) {
  final state = ref.watch(mealPlanProvider);
  return state.savedPlans.length;
});
