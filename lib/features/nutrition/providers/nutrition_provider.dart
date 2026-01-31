import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/nutrition_repository.dart';
import '../data/models/daily_log.dart';
import '../data/models/nutrition_target.dart';
import '../data/models/meal.dart';

// ============================================================================
// Data Providers
// ============================================================================

/// Provider for today's nutrition log
final todayLogProvider = FutureProvider<DailyLog?>((ref) async {
  final repository = ref.watch(nutritionRepositoryProvider);
  return await repository.getTodayLog();
});

/// Provider for current nutrition target
final nutritionTargetProvider = FutureProvider<NutritionTarget?>((ref) async {
  final repository = ref.watch(nutritionRepositoryProvider);
  return await repository.getNutritionTarget();
});

/// Provider for logs in date range
final logsInRangeProvider = FutureProvider.family<List<DailyLog>, DateRange>(
  (ref, dateRange) async {
    final repository = ref.watch(nutritionRepositoryProvider);
    return await repository.getLogsInRange(
      start: dateRange.start,
      end: dateRange.end,
    );
  },
);

/// Provider for average daily calories
final averageCaloriesProvider = FutureProvider.family<double, DateRange>(
  (ref, dateRange) async {
    final repository = ref.watch(nutritionRepositoryProvider);
    return await repository.getAverageDailyCalories(
      start: dateRange.start,
      end: dateRange.end,
    );
  },
);

/// Provider for adherence rate
final adherenceRateProvider = FutureProvider.family<double, DateRange>(
  (ref, dateRange) async {
    final repository = ref.watch(nutritionRepositoryProvider);
    return await repository.getAdherenceRate(
      start: dateRange.start,
      end: dateRange.end,
    );
  },
);

/// Provider for macro trends
final macroTrendsProvider = FutureProvider.family<List<Map<String, dynamic>>, DateRange>(
  (ref, dateRange) async {
    final repository = ref.watch(nutritionRepositoryProvider);
    return await repository.getMacroTrends(
      start: dateRange.start,
      end: dateRange.end,
    );
  },
);

// ============================================================================
// State Notifier for Nutrition Tracking
// ============================================================================

/// State for nutrition tracking
class NutritionTrackingState {
  final DailyLog? todayLog;
  final NutritionTarget? target;
  final List<MealEntry> entries;
  final bool isLoading;
  final String? error;

  const NutritionTrackingState({
    this.todayLog,
    this.target,
    this.entries = const [],
    this.isLoading = false,
    this.error,
  });

  NutritionTrackingState copyWith({
    DailyLog? todayLog,
    NutritionTarget? target,
    List<MealEntry>? entries,
    bool? isLoading,
    String? error,
  }) {
    return NutritionTrackingState(
      todayLog: todayLog ?? this.todayLog,
      target: target ?? this.target,
      entries: entries ?? this.entries,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  /// Calculate remaining calories
  double get remainingCalories {
    if (target == null || todayLog == null) return 0.0;
    return target!.targetCalories - todayLog!.totalCalories;
  }

  /// Calculate remaining protein
  double get remainingProtein {
    if (target == null || todayLog == null) return 0.0;
    return target!.targetMacros.protein - todayLog!.totalMacros.protein;
  }

  /// Get calorie progress percentage
  double get calorieProgress {
    if (target == null || todayLog == null) return 0.0;
    return (todayLog!.totalCalories / target!.targetCalories) * 100;
  }

  /// Get protein progress percentage
  double get proteinProgress {
    if (target == null || todayLog == null) return 0.0;
    return (todayLog!.totalMacros.protein / target!.targetMacros.protein) * 100;
  }
}

/// Notifier for managing nutrition tracking state
class NutritionTrackingNotifier extends StateNotifier<NutritionTrackingState> {
  final NutritionRepository _repository;

  NutritionTrackingNotifier(this._repository) : super(const NutritionTrackingState());

  /// Load today's log and target
  Future<void> loadTodayData() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final log = await _repository.getTodayLog();
      final target = await _repository.getNutritionTarget();

      state = state.copyWith(
        todayLog: log,
        target: target,
        entries: log?.entries ?? [],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load nutrition data: $e',
      );
    }
  }

  /// Add meal entry
  Future<void> addMealEntry(MealEntry entry) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final updatedEntries = [...state.entries, entry];
      
      // Create/update daily log
      final log = DailyLog(
        id: state.todayLog?.id ?? DateTime.now().toIso8601String(),
        date: DateTime.now(),
        entries: updatedEntries,
        targetCalories: state.target?.targetCalories ?? 0,
        targetMacros: state.target?.targetMacros ?? const Macros(protein: 0, carbs: 0, fats: 0),
      );

      await _repository.saveDailyLog(log);
      await loadTodayData(); // Reload
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to add meal: $e',
      );
    }
  }

  /// Remove meal entry
  Future<void> removeMealEntry(String entryId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final updatedEntries = state.entries.where((e) => e.id != entryId).toList();
      
      if (state.todayLog != null) {
        final log = state.todayLog!.copyWith(entries: updatedEntries);
        await _repository.saveDailyLog(log);
        await loadTodayData();
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to remove meal: $e',
      );
    }
  }

  /// Update nutrition target
  Future<void> updateTarget(NutritionTarget target) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.saveNutritionTarget(target);
      await loadTodayData();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update target: $e',
      );
    }
  }

  /// Quick log meal by ID
  Future<void> quickLogMeal(String mealId, double servings) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final meal = await _repository.getMealById(mealId);
      if (meal == null) {
        throw Exception('Meal not found');
      }

      final entry = MealEntry(
        id: DateTime.now().toIso8601String(),
        mealId: mealId,
        mealName: meal.name,
        servings: servings,
        calories: meal.calories * servings,
        macros: Macros(
          protein: meal.macros.protein * servings,
          carbs: meal.macros.carbs * servings,
          fats: meal.macros.fats * servings,
        ),
        timestamp: DateTime.now(),
      );

      await addMealEntry(entry);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to log meal: $e',
      );
    }
  }
}

/// Provider for nutrition tracking state management
final nutritionTrackingProvider = StateNotifierProvider<NutritionTrackingNotifier, NutritionTrackingState>(
  (ref) {
    final repository = ref.watch(nutritionRepositoryProvider);
    return NutritionTrackingNotifier(repository);
  },
);

// ============================================================================
// State Notifier for Meal Library
// ============================================================================

/// State for meal library management
class MealLibraryState {
  final List<Meal> meals;
  final List<Meal> filteredMeals;
  final String searchQuery;
  final bool showOnlyQuick;
  final bool showOnlyHighProtein;
  final bool isLoading;
  final String? error;

  const MealLibraryState({
    this.meals = const [],
    this.filteredMeals = const [],
    this.searchQuery = '',
    this.showOnlyQuick = false,
    this.showOnlyHighProtein = false,
    this.isLoading = false,
    this.error,
  });

  MealLibraryState copyWith({
    List<Meal>? meals,
    List<Meal>? filteredMeals,
    String? searchQuery,
    bool? showOnlyQuick,
    bool? showOnlyHighProtein,
    bool? isLoading,
    String? error,
  }) {
    return MealLibraryState(
      meals: meals ?? this.meals,
      filteredMeals: filteredMeals ?? this.filteredMeals,
      searchQuery: searchQuery ?? this.searchQuery,
      showOnlyQuick: showOnlyQuick ?? this.showOnlyQuick,
      showOnlyHighProtein: showOnlyHighProtein ?? this.showOnlyHighProtein,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier for managing meal library
class MealLibraryNotifier extends StateNotifier<MealLibraryState> {
  final NutritionRepository _repository;

  MealLibraryNotifier(this._repository) : super(const MealLibraryState());

  /// Load all meals
  Future<void> loadMeals() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final meals = await _repository.getAllMeals();
      state = state.copyWith(
        meals: meals,
        filteredMeals: meals,
        isLoading: false,
      );
      _applyFilters();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load meals: $e',
      );
    }
  }

  /// Apply filters to meal list
  void _applyFilters() {
    var filtered = state.meals;

    // Apply search query
    if (state.searchQuery.isNotEmpty) {
      final query = state.searchQuery.toLowerCase();
      filtered = filtered.where((m) => m.name.toLowerCase().contains(query)).toList();
    }

    // Apply quick filter
    if (state.showOnlyQuick) {
      filtered = filtered.where((m) => m.isQuick).toList();
    }

    // Apply high protein filter
    if (state.showOnlyHighProtein) {
      filtered = filtered.where((m) => m.isHighProtein).toList();
    }

    state = state.copyWith(filteredMeals: filtered);
  }

  /// Set search query
  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
    _applyFilters();
  }

  /// Toggle quick filter
  void toggleQuickFilter() {
    state = state.copyWith(showOnlyQuick: !state.showOnlyQuick);
    _applyFilters();
  }

  /// Toggle high protein filter
  void toggleHighProteinFilter() {
    state = state.copyWith(showOnlyHighProtein: !state.showOnlyHighProtein);
    _applyFilters();
  }

  /// Clear all filters
  void clearFilters() {
    state = state.copyWith(
      searchQuery: '',
      showOnlyQuick: false,
      showOnlyHighProtein: false,
    );
    _applyFilters();
  }

  /// Save custom meal
  Future<void> saveMeal(Meal meal) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.saveMeal(meal);
      await loadMeals();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to save meal: $e',
      );
    }
  }
}

/// Provider for meal library state management
final mealLibraryProvider = StateNotifierProvider<MealLibraryNotifier, MealLibraryState>(
  (ref) {
    final repository = ref.watch(nutritionRepositoryProvider);
    return MealLibraryNotifier(repository);
  },
);

// ============================================================================
// Helper Classes
// ============================================================================

/// Date range for filtering logs
class DateRange {
  final DateTime start;
  final DateTime end;

  const DateRange({required this.start, required this.end});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DateRange && start == other.start && end == other.end;

  @override
  int get hashCode => start.hashCode ^ end.hashCode;
}
