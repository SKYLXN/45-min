import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/apple_reminders_service.dart';
import '../../../core/models/user_profile.dart';
import '../data/models/weekly_meal_plan.dart';
import '../data/models/meal.dart';
import '../data/repositories/nutrition_repository.dart';
import '../data/services/shopping_list_service.dart';
import '../data/services/spoonacular_api_service.dart';
import 'nutrition_target_provider.dart';
import '../../../core/providers/user_profile_provider.dart';
import 'recipe_search_provider.dart'; // For spoonacularApiServiceProvider
import 'nutrition_log_provider.dart'; // For nutritionRepositoryProvider

// ============================================================================
// Providers
// ============================================================================

final shoppingListServiceProvider = Provider<ShoppingListService>((ref) {
  return ShoppingListService();
});

final appleRemindersServiceProvider = Provider<AppleRemindersService>((ref) {
  return AppleRemindersService();
});

// ============================================================================
// State Management
// ============================================================================

/// State for weekly meal planning
class WeeklyMealPlanState {
  final WeeklyMealPlan? currentPlan;
  final List<WeeklyMealPlan> savedPlans;
  final Map<String, AggregatedIngredient>? shoppingList;
  final bool isGenerating;
  final bool isExporting;
  final String? error;
  final DateTime? lastGenerated;

  const WeeklyMealPlanState({
    this.currentPlan,
    this.savedPlans = const [],
    this.shoppingList,
    this.isGenerating = false,
    this.isExporting = false,
    this.error,
    this.lastGenerated,
  });

  WeeklyMealPlanState copyWith({
    WeeklyMealPlan? currentPlan,
    List<WeeklyMealPlan>? savedPlans,
    Map<String, AggregatedIngredient>? shoppingList,
    bool? isGenerating,
    bool? isExporting,
    String? error,
    DateTime? lastGenerated,
  }) {
    return WeeklyMealPlanState(
      currentPlan: currentPlan ?? this.currentPlan,
      savedPlans: savedPlans ?? this.savedPlans,
      shoppingList: shoppingList ?? this.shoppingList,
      isGenerating: isGenerating ?? this.isGenerating,
      isExporting: isExporting ?? this.isExporting,
      error: error,
      lastGenerated: lastGenerated ?? this.lastGenerated,
    );
  }
}

/// Notifier for weekly meal plan management
class WeeklyMealPlanNotifier extends StateNotifier<WeeklyMealPlanState> {
  WeeklyMealPlanNotifier(this._ref) : super(const WeeklyMealPlanState()) {
    _init();
  }

  final Ref _ref;

  Future<void> _init() async {
    await loadSavedPlans();
  }

  /// Generate weekly meal plan (2 meals per day × 7 days)
  Future<void> generateWeeklyPlan({DateTime? startDate}) async {
    try {
      print('🍽️ Starting weekly meal plan generation...');
      final start = startDate ?? _getStartOfWeek(DateTime.now());
      
      state = state.copyWith(isGenerating: true, error: null);
      print('✅ State updated to generating');

      // Get nutrition target
      final targetState = _ref.read(nutritionTargetProvider);
      if (targetState.target == null) {
        print('📊 Calculating nutrition target...');
        await _ref.read(nutritionTargetProvider.notifier).calculateTodayTarget();
      }

      final target = _ref.read(nutritionTargetProvider).target;
      if (target == null) {
        throw Exception('Unable to calculate nutrition target');
      }
      
      // Validate target is reasonable (minimum 1200 kcal/day)
      int dailyCalories = target.dailyCalories;
      if (dailyCalories < 1200) {
        print('⚠️ Warning: Calculated target too low ($dailyCalories kcal). Using default 2000 kcal.');
        dailyCalories = 2000;
      }
      print('✅ Nutrition target: $dailyCalories kcal');

      // Get user's dietary restrictions
      print('👤 Fetching user profile...');
      final userProfile = await _ref.read(userProfileProvider.future);
      if (userProfile == null) {
        throw Exception('User profile not found');
      }
      print('✅ User profile loaded');

      final apiService = _ref.read(spoonacularApiServiceProvider);
      final dailyPlans = <DateTime, DayMealPlan>{};

      // Target calories per meal (split daily target by 2)
      final caloriesPerMeal = (dailyCalories / 2).round();
      
      // Calculate reasonable protein target (1g per kg body weight as default)
      final proteinPerMeal = target.macros.protein > 10 
          ? (target.macros.protein / 2).round() 
          : 30; // Default 30g per meal if calculation is too low
          
      print('🍽️ Target per meal: $caloriesPerMeal kcal, $proteinPerMeal g protein');
      print('🚫 Dietary restrictions: ${userProfile.excludedIngredients.length} ingredients excluded');
      print('🥗 Diet type: ${userProfile.spoonacularDiet ?? 'None'}');
      print('⚠️ Intolerances: ${userProfile.spoonacularIntolerances ?? 'None'}');

      // Track used meals to ensure variety
      final usedMealNames = <String>{};
      
      // Cuisine variety for different days
      final cuisineTypes = ['italian', 'asian', 'american', 'mediterranean', 'mexican', 'indian', 'french'];

      // Generate 2 meals for each day of the week
      for (int i = 0; i < 7; i++) {
        print('📅 Generating meals for day ${i + 1}/7...');
        final date = start.add(Duration(days: i));
        final dateKey = DateTime(date.year, date.month, date.day);

        // Select cuisine for variety (optional)
        final cuisineForDay = cuisineTypes[i % cuisineTypes.length];
        
        // Generate first meal (lunch) with variety
        print('  🔍 Searching for meal 1 (cuisine: $cuisineForDay)...');
        final meal1Results = await _searchMealsWithVariety(
          apiService: apiService,
          maxCalories: caloriesPerMeal + 100,
          minProtein: proteinPerMeal,
          userProfile: userProfile,
          usedMealNames: usedMealNames,
          cuisine: i < 3 ? cuisineForDay : null, // First 3 days use cuisine variety
          searchAttempt: 1,
        );

        if (meal1Results.isEmpty) {
          throw Exception('No meals found for day ${i + 1} - meal 1');
        }

        final meal1 = _selectRandomMeal(meal1Results);
        usedMealNames.add(meal1.name.toLowerCase());
        print('  ✅ Meal 1: ${meal1.name} (${meal1.calories} kcal)');

        // Generate second meal (dinner) with variety and exclusions
        print('  🔍 Searching for meal 2...');
        final meal2Results = await _searchMealsWithVariety(
          apiService: apiService,
          maxCalories: caloriesPerMeal + 100,
          minProtein: proteinPerMeal,
          userProfile: userProfile,
          usedMealNames: usedMealNames,
          excludeMealName: meal1.name,
          cuisine: i >= 4 ? cuisineForDay : null, // Last 3 days use cuisine variety
          searchAttempt: 2,
        );

        if (meal2Results.isEmpty) {
          throw Exception('No meals found for day ${i + 1} - meal 2');
        }

        final meal2 = _selectRandomMeal(meal2Results);
        usedMealNames.add(meal2.name.toLowerCase());
        print('  ✅ Meal 2: ${meal2.name} (${meal2.calories} kcal)');

        // Create day plan
        dailyPlans[dateKey] = DayMealPlan.fromMeals(
          date: dateKey,
          meal1: meal1,
          meal2: meal2,
        );

        // Small delay to avoid rate limiting
        await Future.delayed(const Duration(milliseconds: 500));
      }

      // Create weekly plan
      final weeklyPlan = WeeklyMealPlan.create(
        startDate: start,
        dailyPlans: dailyPlans,
      );

      // Save to repository with verification
      final repository = _ref.read(nutritionRepositoryProvider);
      await repository.saveWeeklyMealPlan(weeklyPlan);
      print('💾 Saved weekly meal plan: ${weeklyPlan.id}');
      
      // Verify save was successful
      final savedPlan = await repository.getWeeklyMealPlan(weeklyPlan.id);
      if (savedPlan == null) {
        throw Exception('Failed to save weekly meal plan - verification failed');
      }
      print('✅ Weekly meal plan save verified successfully');

      // Generate shopping list
      final shoppingListService = _ref.read(shoppingListServiceProvider);
      final shoppingList = shoppingListService.generateShoppingList(weeklyPlan);

      state = state.copyWith(
        currentPlan: weeklyPlan,
        shoppingList: shoppingList,
        isGenerating: false,
        lastGenerated: DateTime.now(),
      );

      // Reload saved plans
      await loadSavedPlans();
      print('✅ Weekly meal plan generated successfully!');
    } catch (e, stackTrace) {
      print('❌ Error generating weekly meal plan: $e');
      print('Stack trace: $stackTrace');
      state = state.copyWith(
        isGenerating: false,
        error: e.toString(),
      );
    }
  }

  /// Load saved weekly plans
  Future<void> loadSavedPlans() async {
    try {
      final repository = _ref.read(nutritionRepositoryProvider);
      final plans = await repository.getWeeklyMealPlans();
      
      state = state.copyWith(savedPlans: plans);

      // Set current plan if available
      if (plans.isNotEmpty && state.currentPlan == null) {
        final currentWeekPlan = plans.firstWhere(
          (plan) => plan.isCurrent,
          orElse: () => plans.first,
        );
        
        final shoppingListService = _ref.read(shoppingListServiceProvider);
        final shoppingList = shoppingListService.generateShoppingList(currentWeekPlan);
        
        state = state.copyWith(
          currentPlan: currentWeekPlan,
          shoppingList: shoppingList,
        );
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Export shopping list to Apple Reminders
  Future<bool> exportToReminders({DateTime? dueDate}) async {
    if (state.shoppingList == null || state.shoppingList!.isEmpty) {
      state = state.copyWith(error: 'No shopping list available');
      return false;
    }

    try {
      state = state.copyWith(isExporting: true, error: null);

      final remindersService = _ref.read(appleRemindersServiceProvider);
      final shoppingListService = _ref.read(shoppingListServiceProvider);
      
      // Group by category
      final grouped = shoppingListService.groupByCategory(state.shoppingList!);
      
      // Format title with date
      final dateStr = state.currentPlan != null
          ? _formatDate(state.currentPlan!.startDate)
          : _formatDate(DateTime.now());
      final listTitle = '🛒 45min Shopping - $dateStr';

      // Export to Reminders
      final success = await remindersService.exportCategorizedShoppingList(
        listTitle: listTitle,
        categorizedItems: grouped.map((key, value) => MapEntry(
          key,
          value.map((i) => '${i.name} - ${i.displayText}').toList(),
        )),
        dueDate: dueDate,
      );

      state = state.copyWith(isExporting: false);
      
      if (!success) {
        state = state.copyWith(
          error: 'Failed to export to Reminders. Please check permissions.',
        );
      }

      return success;
    } catch (e) {
      state = state.copyWith(
        isExporting: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Swap a meal in the current plan
  Future<void> swapMeal(DateTime date, int mealIndex) async {
    if (state.currentPlan == null) return;

    try {
      state = state.copyWith(isGenerating: true, error: null);

      final dayPlan = state.currentPlan!.getMealPlanForDay(date);
      if (dayPlan == null) return;

      // Get target for replacement
      final target = _ref.read(nutritionTargetProvider).target;
      if (target == null) return;

      final userProfile = await _ref.read(userProfileProvider.future);
      if (userProfile == null) return;

      final apiService = _ref.read(spoonacularApiServiceProvider);
      
      // Validate target is reasonable (minimum 1200 kcal/day)
      int dailyCalories = target.dailyCalories;
      if (dailyCalories < 1200) {
        dailyCalories = 2000;
      }
      
      final caloriesPerMeal = (dailyCalories / 2).round();
      
      // Calculate reasonable protein target
      final proteinPerMeal = target.macros.protein > 10 
          ? (target.macros.protein / 2).round() 
          : 30; // Default 30g per meal

      // Get existing meals to avoid duplicates
      final existingMeal = mealIndex == 0 ? dayPlan.meal1 : dayPlan.meal2;
      final otherMeal = mealIndex == 0 ? dayPlan.meal2 : dayPlan.meal1;
      
      // Collect all used meal names from the weekly plan for variety
      final usedMealNames = <String>{};
      for (final planEntry in state.currentPlan!.dailyPlans.values) {
        usedMealNames.add(planEntry.meal1.name.toLowerCase());
        usedMealNames.add(planEntry.meal2.name.toLowerCase());
      }

      // Search for replacement with variety
      final results = await _searchMealsWithVariety(
        apiService: apiService,
        maxCalories: caloriesPerMeal + 100,
        minProtein: proteinPerMeal,
        userProfile: userProfile,
        usedMealNames: usedMealNames,
        excludeMealName: existingMeal.name,
        searchAttempt: 1,
      );

      if (results.isEmpty) {
        throw Exception('No alternative meals found');
      }

      final newMeal = _selectRandomMeal(results);
      print('🔄 Swapped meal: ${existingMeal.name} → ${newMeal.name}');

      // Update day plan
      final updatedDayPlan = mealIndex == 0
          ? dayPlan.copyWith(meal1: newMeal)
          : dayPlan.copyWith(meal2: newMeal);

      // Update weekly plan
      final updatedDailyPlans = Map<DateTime, DayMealPlan>.from(
        state.currentPlan!.dailyPlans,
      );
      updatedDailyPlans[date] = updatedDayPlan;

      final updatedPlan = state.currentPlan!.copyWith(
        dailyPlans: updatedDailyPlans,
        lastModified: DateTime.now(),
      );

      // Save to repository
      final repository = _ref.read(nutritionRepositoryProvider);
      await repository.saveWeeklyMealPlan(updatedPlan);

      // Regenerate shopping list
      final shoppingListService = _ref.read(shoppingListServiceProvider);
      final shoppingList = shoppingListService.generateShoppingList(updatedPlan);

      state = state.copyWith(
        currentPlan: updatedPlan,
        shoppingList: shoppingList,
        isGenerating: false,
      );

      await loadSavedPlans();
    } catch (e) {
      state = state.copyWith(
        isGenerating: false,
        error: e.toString(),
      );
    }
  }

  /// Delete a weekly plan
  Future<void> deletePlan(String planId) async {
    try {
      final repository = _ref.read(nutritionRepositoryProvider);
      await repository.deleteWeeklyMealPlan(planId);
      
      await loadSavedPlans();
      
      if (state.currentPlan?.id == planId) {
        state = state.copyWith(
          currentPlan: null,
          shoppingList: null,
        );
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Get start of week (Monday)
  DateTime _getStartOfWeek(DateTime date) {
    final weekday = date.weekday;
    final daysToSubtract = weekday - 1; // Monday is 1
    return DateTime(date.year, date.month, date.day)
        .subtract(Duration(days: daysToSubtract));
  }

  /// Format date for display
  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Search for meals with variety and dietary restrictions
  Future<List<Meal>> _searchMealsWithVariety({
    required SpoonacularApiService apiService,
    required int maxCalories,
    required int minProtein,
    required UserProfile userProfile,
    required Set<String> usedMealNames,
    String? excludeMealName,
    String? cuisine,
    required int searchAttempt,
  }) async {
    // Build comprehensive exclusion list
    final allExclusions = <String>[
      ...userProfile.excludedIngredients,
      ...usedMealNames.map((name) => name.split(' ').first), // Exclude by first word
    ];
    
    if (excludeMealName != null) {
      allExclusions.add(excludeMealName);
      allExclusions.add(excludeMealName.split(' ').first);
    }

    // First attempt with strict parameters
    var results = await apiService.searchRecipes(
      maxCalories: maxCalories,
      minProtein: minProtein,
      diet: userProfile.spoonacularDiet,
      excludeIngredients: allExclusions,
      intolerances: userProfile.spoonacularIntolerances,
      cuisine: cuisine,
      number: 10, // Request multiple options
      offset: searchAttempt * 5, // Add variety with offset
    );

    // If no results and we specified cuisine, try again without cuisine constraint
    if (results.isEmpty && cuisine != null) {
      print('    ⚠️ No results with cuisine constraint, trying without...');
      results = await apiService.searchRecipes(
        maxCalories: maxCalories,
        minProtein: minProtein,
        diet: userProfile.spoonacularDiet,
        excludeIngredients: allExclusions,
        intolerances: userProfile.spoonacularIntolerances,
        number: 10,
        offset: searchAttempt * 3,
      );
    }

    // If still no results, try with relaxed protein requirements
    if (results.isEmpty) {
      print('    ⚠️ No results with protein constraint, trying with relaxed requirements...');
      results = await apiService.searchRecipes(
        maxCalories: maxCalories + 200, // Allow more calories
        minProtein: (minProtein * 0.7).round(), // Reduce protein requirement
        diet: userProfile.spoonacularDiet,
        excludeIngredients: userProfile.excludedIngredients, // Use only core restrictions
        intolerances: userProfile.spoonacularIntolerances,
        number: 15,
        offset: 0,
      );
    }

    // Filter out already used meals
    final filteredResults = results.where((meal) {
      final mealNameLower = meal.name.toLowerCase();
      return !usedMealNames.any((usedName) => 
        mealNameLower.contains(usedName) || usedName.contains(mealNameLower.split(' ').first));
    }).toList();

    print('    📊 Found ${results.length} total results, ${filteredResults.length} after filtering duplicates');
    return filteredResults.isNotEmpty ? filteredResults : results;
  }

  /// Select a random meal from the results for variety
  Meal _selectRandomMeal(List<Meal> meals) {
    if (meals.length == 1) return meals.first;
    
    // Weighted selection - prefer meals in the middle of the list (balanced nutrition)
    final random = DateTime.now().millisecondsSinceEpoch % meals.length;
    final selectedIndex = meals.length > 3 
        ? (random % (meals.length ~/ 2)) + (meals.length ~/ 4) // Middle section
        : random;
    
    return meals[selectedIndex.clamp(0, meals.length - 1)];
  }
}

// ============================================================================
// Provider Definitions
// ============================================================================

final weeklyMealPlanProvider =
    StateNotifierProvider<WeeklyMealPlanNotifier, WeeklyMealPlanState>((ref) {
  return WeeklyMealPlanNotifier(ref);
});

/// Current weekly meal plan
final currentWeeklyPlanProvider = Provider<WeeklyMealPlan?>((ref) {
  return ref.watch(weeklyMealPlanProvider).currentPlan;
});

/// Shopping list
final shoppingListProvider =
    Provider<Map<String, AggregatedIngredient>?>((ref) {
  return ref.watch(weeklyMealPlanProvider).shoppingList;
});

/// Is generating plan
final isGeneratingWeeklyPlanProvider = Provider<bool>((ref) {
  return ref.watch(weeklyMealPlanProvider).isGenerating;
});

/// Has current plan
final hasCurrentWeeklyPlanProvider = Provider<bool>((ref) {
  return ref.watch(weeklyMealPlanProvider).currentPlan != null;
});

/// Total shopping items
final totalShoppingItemsProvider = Provider<int>((ref) {
  final shoppingList = ref.watch(shoppingListProvider);
  return shoppingList?.length ?? 0;
});
