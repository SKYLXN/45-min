import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../data/models/daily_log.dart';
import '../data/models/meal.dart';
import '../data/repositories/nutrition_repository.dart';
import 'nutrition_target_provider.dart';
import '../../../core/constants/app_constants.dart';

// ============================================================================
// State Management
// ============================================================================

/// State for nutrition logging
class NutritionLogState {
  final DailyLog? todayLog;
  final List<DailyLog> recentLogs;
  final bool isLoading;
  final String? error;
  final DateTime? lastUpdated;

  const NutritionLogState({
    this.todayLog,
    this.recentLogs = const [],
    this.isLoading = false,
    this.error,
    this.lastUpdated,
  });

  NutritionLogState copyWith({
    DailyLog? todayLog,
    List<DailyLog>? recentLogs,
    bool? isLoading,
    String? error,
    DateTime? lastUpdated,
  }) {
    return NutritionLogState(
      todayLog: todayLog ?? this.todayLog,
      recentLogs: recentLogs ?? this.recentLogs,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  /// Get total calories consumed today
  int get caloriesConsumed {
    return todayLog?.totalCalories ?? 0;
  }

  /// Get total protein consumed today
  int get proteinConsumed {
    return todayLog?.totalMacros.protein.round() ?? 0;
  }

  /// Get total carbs consumed today
  int get carbsConsumed {
    return todayLog?.totalMacros.carbs.round() ?? 0;
  }

  /// Get total fats consumed today
  int get fatsConsumed {
    return todayLog?.totalMacros.fats.round() ?? 0;
  }

  /// Get number of meals logged today
  int get mealsLoggedCount {
    return todayLog?.meals.length ?? 0;
  }

  /// Check if workout was completed today
  bool get workoutCompletedToday {
    return todayLog?.workoutCompleted ?? false;
  }

  /// Calculate calorie progress percentage
  double get calorieProgress {
    if (todayLog == null) return 0.0;
    if (todayLog!.targetCalories == 0) return 0.0;
    return (caloriesConsumed / todayLog!.targetCalories).clamp(0.0, 2.0);
  }

  /// Calculate protein progress percentage
  double get proteinProgress {
    if (todayLog == null) return 0.0;
    final target = todayLog!.targetMacros.protein;
    if (target == 0) return 0.0;
    return (proteinConsumed / target).clamp(0.0, 2.0);
  }

  /// Calculate carbs progress percentage
  double get carbsProgress {
    if (todayLog == null) return 0.0;
    final target = todayLog!.targetMacros.carbs;
    if (target == 0) return 0.0;
    return (carbsConsumed / target).clamp(0.0, 2.0);
  }

  /// Calculate fats progress percentage
  double get fatsProgress {
    if (todayLog == null) return 0.0;
    final target = todayLog!.targetMacros.fats;
    if (target == 0) return 0.0;
    return (fatsConsumed / target).clamp(0.0, 2.0);
  }
}

/// Notifier for nutrition log management
class NutritionLogNotifier extends StateNotifier<NutritionLogState> {
  NutritionLogNotifier(this._ref) : super(const NutritionLogState()) {
    _initialize();
  }

  final Ref _ref;
  final _uuid = const Uuid();

  /// Initialize with today's log and load recent history
  Future<void> _initialize() async {
    try {
      print('🍽️ Initializing nutrition log provider...');
      
      // Load today's log first (most important)
      await loadTodayLog();
      
      // Load recent logs for context (async to avoid blocking)
      loadRecentLogs().catchError((e) {
        print('⚠️ Warning: Failed to load recent logs: $e');
        // Don't block initialization for recent logs failure
      });
      
      print('✅ Nutrition log provider initialized');
    } catch (e) {
      print('❌ Error initializing nutrition log provider: $e');
      // Set error state but don't crash the app
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  /// Load today's nutrition log
  Future<void> loadTodayLog() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final repository = _ref.read(nutritionRepositoryProvider);
      final log = await repository.getTodayLog(userId: AppConstants.defaultUserId);

      // If no log exists, create one with current target
      if (log == null) {
        final target = _ref.read(nutritionTargetProvider).target;
        if (target != null) {
          final newLog = DailyLog(
            id: 'log_${DateTime.now().millisecondsSinceEpoch}',
            userId: AppConstants.defaultUserId, // TODO: Get from user profile
            date: DateTime.now(),
            meals: [],
            targetCalories: target.dailyCalories,
            targetMacros: target.macros,
            workoutCompleted: false,
          );

          await repository.saveDailyLog(newLog);
          state = state.copyWith(
            todayLog: newLog,
            isLoading: false,
            lastUpdated: DateTime.now(),
          );
        } else {
          state = state.copyWith(isLoading: false);
        }
      } else {
        state = state.copyWith(
          todayLog: log,
          isLoading: false,
          lastUpdated: DateTime.now(),
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Load recent logs (last 7 days)
  Future<void> loadRecentLogs({int days = 7}) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final repository = _ref.read(nutritionRepositoryProvider);
      final logs = await repository.getRecentLogs(userId: AppConstants.defaultUserId, days: days);

      state = state.copyWith(
        recentLogs: logs,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Log a meal
  Future<void> logMeal(Meal meal) async {
    try {
      if (state.todayLog == null) {
        await loadTodayLog();
        if (state.todayLog == null) {
          throw Exception('Unable to create daily log');
        }
      }

      final currentLog = state.todayLog!;
      
      // Convert Meal to MealEntry
      final mealEntry = MealEntry.fromMeal(
        id: _uuid.v4(),
        meal: meal,
        mealType: 'meal', // Default type
        servings: 1.0,
      );
      
      final updatedMeals = List<MealEntry>.from(currentLog.meals)..add(mealEntry);

      final updatedLog = DailyLog(
        id: currentLog.id,
        userId: currentLog.userId,
        date: currentLog.date,
        meals: updatedMeals,
        targetCalories: currentLog.targetCalories,
        targetMacros: currentLog.targetMacros,
        workoutCompleted: currentLog.workoutCompleted,
        notes: currentLog.notes,
      );

      final repository = _ref.read(nutritionRepositoryProvider);
      await repository.updateDailyLog(updatedLog);

      state = state.copyWith(
        todayLog: updatedLog,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Remove a meal from today's log
  Future<void> removeMeal(String mealId) async {
    try {
      if (state.todayLog == null) return;

      final currentLog = state.todayLog!;
      final updatedMeals = currentLog.meals.where((m) => m.id != mealId).toList();

      final updatedLog = DailyLog(
        id: currentLog.id,
        userId: currentLog.userId,
        date: currentLog.date,
        meals: updatedMeals,
        targetCalories: currentLog.targetCalories,
        targetMacros: currentLog.targetMacros,
        workoutCompleted: currentLog.workoutCompleted,
        notes: currentLog.notes,
      );

      final repository = _ref.read(nutritionRepositoryProvider);
      await repository.updateDailyLog(updatedLog);

      state = state.copyWith(
        todayLog: updatedLog,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Update a meal in today's log
  Future<void> updateMeal(MealEntry updatedMealEntry) async {
    try {
      if (state.todayLog == null) return;

      final currentLog = state.todayLog!;
      final updatedMeals = currentLog.meals.map((m) {
        return m.id == updatedMealEntry.id ? updatedMealEntry : m;
      }).toList();

      final updatedLog = DailyLog(
        id: currentLog.id,
        userId: currentLog.userId,
        date: currentLog.date,
        meals: updatedMeals,
        targetCalories: currentLog.targetCalories,
        targetMacros: currentLog.targetMacros,
        workoutCompleted: currentLog.workoutCompleted,
        notes: currentLog.notes,
      );

      final repository = _ref.read(nutritionRepositoryProvider);
      await repository.updateDailyLog(updatedLog);

      state = state.copyWith(
        todayLog: updatedLog,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Mark workout as completed for today
  Future<void> markWorkoutCompleted(bool completed) async {
    try {
      if (state.todayLog == null) {
        await loadTodayLog();
        if (state.todayLog == null) return;
      }

      final currentLog = state.todayLog!;
      final updatedLog = currentLog.copyWith(
        workoutCompleted: completed,
      );

      final repository = _ref.read(nutritionRepositoryProvider);
      await repository.updateDailyLog(updatedLog);

      state = state.copyWith(
        todayLog: updatedLog,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Clear all meals for today
  Future<void> clearTodayMeals() async {
    try {
      if (state.todayLog == null) return;

      final currentLog = state.todayLog!;
      final updatedLog = currentLog.copyWith(
        meals: [],
      );

      final repository = _ref.read(nutritionRepositoryProvider);
      await repository.updateDailyLog(updatedLog);

      state = state.copyWith(
        todayLog: updatedLog,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Clear error state
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Refresh today's log
  Future<void> refresh() async {
    await loadTodayLog();
  }
}

// ============================================================================
// Providers
// ============================================================================

/// Main provider for nutrition log state
final nutritionLogProvider =
    StateNotifierProvider<NutritionLogNotifier, NutritionLogState>((ref) {
  return NutritionLogNotifier(ref);
});

/// Provider for today's nutrition log
final todayNutritionLogProvider = Provider<DailyLog?>((ref) {
  final state = ref.watch(nutritionLogProvider);
  return state.todayLog;
});

/// Provider for calories consumed today
final caloriesConsumedProvider = Provider<int>((ref) {
  final state = ref.watch(nutritionLogProvider);
  return state.caloriesConsumed;
});

/// Provider for macros consumed today
final macrosConsumedProvider = Provider<Map<String, int>>((ref) {
  final state = ref.watch(nutritionLogProvider);
  return {
    'protein': state.proteinConsumed,
    'carbs': state.carbsConsumed,
    'fats': state.fatsConsumed,
  };
});

/// Provider for calorie progress percentage
final calorieProgressProvider = Provider<double>((ref) {
  final state = ref.watch(nutritionLogProvider);
  return state.calorieProgress;
});

/// Provider for macro progress percentages
final macroProgressProvider = Provider<Map<String, double>>((ref) {
  final state = ref.watch(nutritionLogProvider);
  return {
    'protein': state.proteinProgress,
    'carbs': state.carbsProgress,
    'fats': state.fatsProgress,
  };
});

/// Provider for meals logged today
final todayMealsProvider = Provider<List<MealEntry>>((ref) {
  final log = ref.watch(todayNutritionLogProvider);
  return log?.meals ?? [];
});

/// Provider for meals count today
final mealsCountProvider = Provider<int>((ref) {
  final state = ref.watch(nutritionLogProvider);
  return state.mealsLoggedCount;
});

/// Provider to check if workout was completed today
final workoutCompletedTodayProvider = Provider<bool>((ref) {
  final state = ref.watch(nutritionLogProvider);
  return state.workoutCompletedToday;
});

/// Provider for calorie deficit/surplus
final calorieDeficitProvider = Provider<int>((ref) {
  final state = ref.watch(nutritionLogProvider);
  if (state.todayLog == null) return 0;
  return state.caloriesConsumed - state.todayLog!.targetCalories;
});

/// Provider to check if target calories reached
final targetCaloriesReachedProvider = Provider<bool>((ref) {
  final progress = ref.watch(calorieProgressProvider);
  return progress >= 0.95 && progress <= 1.05; // Within 5% of target
});
