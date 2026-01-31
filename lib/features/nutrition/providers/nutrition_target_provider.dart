import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/user_profile.dart';
import '../../../core/models/body_metrics.dart';
import '../../../core/providers/user_profile_provider.dart';
import '../../../core/services/bmr_calculator_service.dart';
import '../../body_analytics/providers/body_analytics_provider.dart';
import '../../body_analytics/providers/recovery_provider.dart';
import '../../body_analytics/data/services/health_service.dart';
import '../../workout_mode/data/repositories/workout_repository.dart' as workout_repo;
import '../../smart_planner/providers/smart_planner_provider.dart';
import '../data/models/nutrition_target.dart';
import '../data/services/nutrition_calculator_service.dart';
import '../data/services/nutrition_integration_service.dart';

// ============================================================================
// Service Providers
// ============================================================================

/// Singleton provider for NutritionCalculatorService
final nutritionCalculatorServiceProvider = Provider<NutritionCalculatorService>((ref) {
  return NutritionCalculatorService();
});

/// Singleton provider for NutritionIntegrationService
final nutritionIntegrationServiceProvider = Provider<NutritionIntegrationService>((ref) {
  final calculatorService = ref.read(nutritionCalculatorServiceProvider);
  return NutritionIntegrationService(calculatorService);
});

// ============================================================================
// State Management
// ============================================================================

/// State for nutrition target calculations
class NutritionTargetState {
  final NutritionTarget? target;
  final bool isLoading;
  final String? error;
  final bool isWorkoutDay;
  final DateTime? lastCalculated;

  const NutritionTargetState({
    this.target,
    this.isLoading = false,
    this.error,
    this.isWorkoutDay = false,
    this.lastCalculated,
  });

  NutritionTargetState copyWith({
    NutritionTarget? target,
    bool? isLoading,
    String? error,
    bool? isWorkoutDay,
    DateTime? lastCalculated,
  }) {
    return NutritionTargetState(
      target: target ?? this.target,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isWorkoutDay: isWorkoutDay ?? this.isWorkoutDay,
      lastCalculated: lastCalculated ?? this.lastCalculated,
    );
  }
}

/// Notifier for nutrition target management
class NutritionTargetNotifier extends StateNotifier<NutritionTargetState> {
  NutritionTargetNotifier(this._ref) : super(const NutritionTargetState()) {
    // Initialize by calculating today's target
    calculateTodayTarget();
    
    // Watch for weight changes and auto-recalculate BMR
    _watchWeightChanges();
  }

  final Ref _ref;
  double? _lastKnownWeight;

  /// Watch for body metrics changes and recalculate when weight changes
  void _watchWeightChanges() {
    _ref.listen<AsyncValue<BodyMetrics?>>(
      latestBodyMetricsProvider,
      (previous, next) {
        next.whenData((metrics) {
          if (metrics != null) {
            // Check if weight has changed significantly (more than 0.1kg)
            if (_lastKnownWeight == null || 
                (metrics.weight - _lastKnownWeight!).abs() >= 0.1) {
              _lastKnownWeight = metrics.weight;
              
              // Auto-recalculate nutrition targets with new BMR
              print('Weight changed to ${metrics.weight}kg - Recalculating nutrition targets...');
              calculateTodayTarget();
            }
          }
        });
      },
    );
  }

  /// Calculate today's nutrition target
  Future<void> calculateTodayTarget() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      print('🍽️ Calculating nutrition target...');

      // Get user profile first (required for BMR calculation)
      final userProfile = await _ref.read(userProfileProvider.future);
      if (userProfile == null) {
        throw Exception('User profile not found');
      }

      print('✅ User profile: age=${userProfile.age}, height=${userProfile.height}, gender=${userProfile.gender}');

      // Get latest body metrics (for weight)
      final latestMetrics = await _ref.read(latestBodyMetricsProvider.future);
      
      // If no body metrics, try to fetch from Apple Health
      if (latestMetrics == null) {
        print('⚠️ No body metrics found. Attempting to fetch from Apple Health...');
        final healthService = HealthService();
        final hasPermission = await healthService.checkAuthorizationStatus();
        
        if (hasPermission) {
          final healthMetrics = await healthService.fetchLatestBodyMetrics();
          if (healthMetrics != null) {
            print('✅ Fetched metrics from Apple Health: weight=${healthMetrics.weight}kg');
            // Use health metrics for calculation
            final calculatorService = _ref.read(nutritionCalculatorServiceProvider);
            var target = calculatorService.calculateFromBodyMetrics(
              metrics: healthMetrics,
              goal: userProfile.primaryGoal,
              activityLevel: userProfile.activityLevel,
              isWorkoutDay: await _checkIfWorkoutDay(),
            );
            
            state = state.copyWith(
              target: target,
              isLoading: false,
              isWorkoutDay: await _checkIfWorkoutDay(),
            );
            return;
          }
        }
        
        throw Exception('No body metrics available. Please sync with Apple Health or add manual entry.');
      }

      print('✅ Body metrics found: weight=${latestMetrics.weight}kg, BMR=${latestMetrics.bmr}kcal');

      // Check if BMR is reasonable (should be >1000 for adults)
      int bmr = latestMetrics.bmr;
      if (bmr < 1000) {
        print('⚠️ BMR too low ($bmr kcal), calculating from user profile...');
        // Calculate BMR from user profile + current weight
        final bmrCalculator = _ref.read(bmrCalculatorServiceProvider);
        bmr = bmrCalculator.calculateFromProfile(
          profile: userProfile,
          currentWeight: latestMetrics.weight,
        );
        print('✅ Calculated BMR: $bmr kcal');
      }

      // Check if today is a workout day
      final isWorkoutDay = await _checkIfWorkoutDay();

      // Calculate base target using service
      final calculatorService = _ref.read(nutritionCalculatorServiceProvider);
      var target = calculatorService.calculateFromBodyMetrics(
        metrics: latestMetrics.copyWith(bmr: bmr), // Use calculated BMR if needed
        goal: userProfile.primaryGoal,
        activityLevel: userProfile.activityLevel,
        isWorkoutDay: isWorkoutDay,
      );

      // Apply weekly program adjustments if available
      final smartPlannerState = _ref.read(smartPlannerProvider);
      if (smartPlannerState.currentProgram != null) {
        final integrationService = _ref.read(nutritionIntegrationServiceProvider);
        target = integrationService.adjustForWeeklyProgram(
          baseTarget: target,
          program: smartPlannerState.currentProgram!,
          date: DateTime.now(),
        );
      }

      // Apply recovery adjustments if available
      final recoveryState = _ref.read(recoveryProvider);
      if (recoveryState.recoveryScore != null && recoveryState.recoveryScore! < 70) {
        final integrationService = _ref.read(nutritionIntegrationServiceProvider);
        target = integrationService.adjustForRecovery(
          baseTarget: target,
          recoveryScore: recoveryState.recoveryScore!,
        );
      }

      state = state.copyWith(
        target: target,
        isLoading: false,
        isWorkoutDay: isWorkoutDay,
        lastCalculated: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Calculate custom target with specific parameters
  Future<void> calculateCustomTarget({
    required double bmr,
    required String goal,
    required String activityLevel,
    required double currentWeight,
    bool isWorkoutDay = false,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final calculatorService = _ref.read(nutritionCalculatorServiceProvider);
      
      // Calculate calories
      final calories = calculatorService.calculateDailyCalories(
        bmr: bmr,
        goal: goal,
        activityLevel: activityLevel,
        isWorkoutDay: isWorkoutDay,
      );

      // Calculate target with macros
      final target = calculatorService.calculateMacros(
        calories: calories,
        weight: currentWeight,
        goal: goal,
        isWorkoutDay: isWorkoutDay,
      );

      state = state.copyWith(
        target: target,
        isLoading: false,
        isWorkoutDay: isWorkoutDay,
        lastCalculated: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Adjust target for workout day
  Future<void> adjustForWorkoutDay(bool isWorkoutDay) async {
    if (state.target == null) {
      await calculateTodayTarget();
      return;
    }

    try {
      state = state.copyWith(isLoading: true, error: null);

      // Get user profile
      final userProfile = await _ref.read(userProfileProvider.future);
      if (userProfile == null) {
        throw Exception('User profile not found');
      }

      // Get latest body metrics
      final latestMetrics = await _ref.read(latestBodyMetricsProvider.future);
      if (latestMetrics == null) {
        throw Exception('No body metrics available');
      }

      // Recalculate with workout day flag
      final calculatorService = _ref.read(nutritionCalculatorServiceProvider);
      final target = calculatorService.calculateFromBodyMetrics(
        metrics: latestMetrics,
        goal: userProfile.primaryGoal,
        activityLevel: userProfile.activityLevel,
        isWorkoutDay: isWorkoutDay,
      );

      state = state.copyWith(
        target: target,
        isLoading: false,
        isWorkoutDay: isWorkoutDay,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Get post-workout meal recommendation
  Future<NutritionTarget?> getPostWorkoutMeal() async {
    try {
      // Get user profile
      final userProfile = await _ref.read(userProfileProvider.future);
      if (userProfile == null) return null;

      // Get latest body metrics
      final latestMetrics = await _ref.read(latestBodyMetricsProvider.future);
      if (latestMetrics == null) return null;

      final calculatorService = _ref.read(nutritionCalculatorServiceProvider);
      return calculatorService.calculatePostWorkoutMeal(
        weight: latestMetrics.weight,
      );
    } catch (e) {
      return null;
    }
  }

  /// Get pre-workout meal recommendation
  Future<NutritionTarget?> getPreWorkoutMeal() async {
    try {
      // Get user profile
      final userProfile = await _ref.read(userProfileProvider.future);
      if (userProfile == null) return null;

      // Get latest body metrics
      final latestMetrics = await _ref.read(latestBodyMetricsProvider.future);
      if (latestMetrics == null) return null;

      final calculatorService = _ref.read(nutritionCalculatorServiceProvider);
      return calculatorService.calculatePreWorkoutMeal(
        weight: latestMetrics.weight,
      );
    } catch (e) {
      return null;
    }
  }

  /// Check if today is a workout day
  Future<bool> _checkIfWorkoutDay() async {
    try {
      // Get today's workout session
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final sessions = await _ref
          .read(workout_repo.workoutRepositoryProvider)
          .getSessionHistory();
      
      // Filter sessions for today
      final todaySessions = sessions.where((s) => 
        s.startTime?.isAfter(startOfDay) == true && s.startTime?.isBefore(endOfDay) == true
      ).toList();

      return todaySessions.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Clear error state
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Refresh target calculation
  Future<void> refresh() async {
    await calculateTodayTarget();
  }
}

// ============================================================================
// Providers
// ============================================================================

/// Main provider for nutrition target state
final nutritionTargetProvider =
    StateNotifierProvider<NutritionTargetNotifier, NutritionTargetState>((ref) {
  return NutritionTargetNotifier(ref);
});

/// Provider for today's nutrition target (auto-calculated)
final dailyNutritionTargetProvider = Provider<NutritionTarget?>((ref) {
  // Simply watch and return the current target from the state
  final state = ref.watch(nutritionTargetProvider);
  return state.target;
});

/// Provider to check if today is a workout day
final isWorkoutDayProvider = FutureProvider<bool>((ref) async {
  final today = DateTime.now();
  final startOfDay = DateTime(today.year, today.month, today.day);
  final endOfDay = startOfDay.add(const Duration(days: 1));

  final sessions = await ref
      .read(workout_repo.workoutRepositoryProvider)
      .getSessionHistory();
  
  // Filter sessions for today
  final todaySessions = sessions.where((s) => 
    s.startTime?.isAfter(startOfDay) == true && s.startTime?.isBefore(endOfDay) == true
  ).toList();

  return todaySessions.isNotEmpty;
});

/// Provider for post-workout meal recommendation
final postWorkoutMealProvider = FutureProvider<NutritionTarget?>((ref) async {
  return await ref.read(nutritionTargetProvider.notifier).getPostWorkoutMeal();
});

/// Provider for pre-workout meal recommendation
final preWorkoutMealProvider = FutureProvider<NutritionTarget?>((ref) async {
  return await ref.read(nutritionTargetProvider.notifier).getPreWorkoutMeal();
});

/// Provider to check if target needs recalculation
final targetNeedsUpdateProvider = Provider<bool>((ref) {
  final state = ref.watch(nutritionTargetProvider);
  
  if (state.target == null) return true;
  if (state.lastCalculated == null) return true;

  // Recalculate if older than 12 hours
  final now = DateTime.now();
  final hoursSinceCalculation = now.difference(state.lastCalculated!).inHours;
  
  return hoursSinceCalculation > 12;
});
