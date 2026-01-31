import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/data_persistence_service.dart';
import '../../features/nutrition/providers/nutrition_log_provider.dart';
import '../../features/nutrition/providers/weekly_meal_plan_provider.dart';
import '../../features/smart_planner/providers/smart_planner_provider.dart';
import '../../features/smart_planner/providers/workout_provider.dart';
import '../../features/body_analytics/providers/body_analytics_provider.dart';

/// Provider for the app initialization service
final appInitializationServiceProvider = Provider<AppInitializationService>((ref) {
  return AppInitializationService(ref);
});

/// Service responsible for initializing the app and ensuring data persistence
class AppInitializationService {
  final Ref _ref;
  bool _isInitialized = false;
  String? _initializationError;

  AppInitializationService(this._ref);

  /// Get initialization status
  bool get isInitialized => _isInitialized;
  String? get initializationError => _initializationError;

  /// Initialize the entire app with proper data persistence
  Future<bool> initialize() async {
    if (_isInitialized) {
      print('ℹ️ App already initialized');
      return true;
    }

    print('🚀 Starting app initialization...');
    final stopwatch = Stopwatch()..start();

    try {
      // Step 1: Initialize data persistence service
      await _initializeDataPersistence();

      // Step 2: Initialize providers with data
      await _initializeProviders();

      // Step 3: Perform data integrity check
      await _performIntegrityCheck();

      stopwatch.stop();
      _isInitialized = true;
      print('✅ App initialization completed in ${stopwatch.elapsedMilliseconds}ms');
      
      return true;
    } catch (e, stackTrace) {
      stopwatch.stop();
      _initializationError = e.toString();
      print('❌ App initialization failed after ${stopwatch.elapsedMilliseconds}ms: $e');
      if (kDebugMode) {
        print('Stack trace: $stackTrace');
      }
      return false;
    }
  }

  /// Initialize data persistence service
  Future<void> _initializeDataPersistence() async {
    print('💾 Initializing data persistence...');
    
    try {
      final persistenceService = _ref.read(dataPersistenceServiceProvider);
      await persistenceService.initialize();
      print('✅ Data persistence service initialized');
    } catch (e) {
      print('❌ Data persistence initialization failed: $e');
      rethrow;
    }
  }

  /// Initialize all providers with their data
  Future<void> _initializeProviders() async {
    print('🔧 Initializing providers...');
    
    final futures = <Future<void>>[];

    try {
      // Initialize nutrition providers
      futures.add(_initializeNutritionProviders());
      
      // Initialize workout/training providers
      futures.add(_initializeWorkoutProviders());
      
      // Initialize body analytics provider
      futures.add(_initializeBodyAnalyticsProvider());

      // Wait for all providers to initialize (with timeout)
      await Future.wait(futures).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Provider initialization timed out', const Duration(seconds: 30));
        },
      );

      print('✅ All providers initialized');
    } catch (e) {
      print('❌ Provider initialization failed: $e');
      rethrow;
    }
  }

  /// Initialize nutrition-related providers
  Future<void> _initializeNutritionProviders() async {
    try {
      // Initialize nutrition log provider (loads today's log)
      final nutritionLogNotifier = _ref.read(nutritionLogProvider.notifier);
      await nutritionLogNotifier.loadTodayLog();
      
      // Load recent logs in background (don't block initialization)
      unawaited(nutritionLogNotifier.loadRecentLogs());
      
      // Initialize weekly meal plan provider
      final weeklyMealPlanNotifier = _ref.read(weeklyMealPlanProvider.notifier);
      unawaited(weeklyMealPlanNotifier.loadSavedPlans());
      
      print('🍎 Nutrition providers initialized');
    } catch (e) {
      print('❌ Nutrition provider initialization failed: $e');
      rethrow;
    }
  }

  /// Initialize workout/training providers
  Future<void> _initializeWorkoutProviders() async {
    try {
      // First, migrate any old workout data to use consistent user ID
      await _migrateWorkoutData();
      
      // Initialize smart planner with proper initialization
      final smartPlannerNotifier = _ref.read(smartPlannerProvider.notifier);
      await smartPlannerNotifier.initialize();
      
      // Preload workout session history to ensure persistence
      _ref.read(sessionHistoryProvider);
      
      // Preload current week program
      _ref.read(currentWeekProgramProvider);
      
      print('💪 Workout providers initialized');
    } catch (e) {
      print('❌ Workout provider initialization failed: $e');
      rethrow;
    }
  }

  /// Migrate old workout data to use consistent user ID
  Future<void> _migrateWorkoutData() async {
    try {
      final persistenceService = _ref.read(dataPersistenceServiceProvider);
      await persistenceService.migrateWorkoutUserIds();
      print('🔄 Workout data migration completed');
    } catch (e) {
      print('⚠️ Workout data migration failed: $e');
      // Don't fail app initialization for migration issues
    }
  }

  /// Initialize body analytics provider
  Future<void> _initializeBodyAnalyticsProvider() async {
    try {
      // Just access the provider to initialize it
      _ref.read(bodyAnalyticsProvider);
      
      print('📊 Body analytics provider initialized');
    } catch (e) {
      print('❌ Body analytics provider initialization failed: $e');
      // Don't fail for body analytics issues
    }
  }

  /// Perform data integrity check
  Future<void> _performIntegrityCheck() async {
    print('🔍 Performing data integrity check...');
    
    try {
      final persistenceService = _ref.read(dataPersistenceServiceProvider);
      final report = await persistenceService.verifyDataIntegrity();
      
      if (report.isHealthy) {
        print('✅ Data integrity check passed');
      } else {
        print('⚠️ Data integrity issues found:');
        print(report.summary);
        // Log issues but don't fail initialization
      }
    } catch (e) {
      print('⚠️ Data integrity check failed: $e');
      // Don't fail initialization for integrity check issues
    }
  }

  /// Reset initialization state (for testing or recovery)
  void reset() {
    _isInitialized = false;
    _initializationError = null;
    print('🔄 App initialization state reset');
  }

  /// Get initialization summary for debugging
  Map<String, dynamic> getInitializationSummary() {
    return {
      'initialized': _isInitialized,
      'error': _initializationError,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}

/// Helper function to avoid blocking on background tasks
void unawaited(Future<void> future) {
  future.catchError((e) {
    print('⚠️ Background task failed: $e');
  });
}