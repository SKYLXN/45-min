import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/body_analytics_repository.dart';
import '../../../core/models/body_metrics.dart';
import '../data/repositories/body_analytics_repository.dart';
import '../data/services/health_service.dart';
import '../data/services/recovery_service.dart';
import 'body_analytics_provider.dart';

/// Provider for RecoveryService
final recoveryServiceProvider = Provider<RecoveryService>((ref) {
  final healthService = HealthService();
  return RecoveryService(healthService);
});

/// State for recovery data
class RecoveryState {
  final double? recoveryScore;
  final RecoveryMetrics? metrics;
  final RecoveryInsights? insights;
  final String? recommendation;
  final bool isLoading;
  final String? error;
  
  const RecoveryState({
    this.recoveryScore,
    this.metrics,
    this.insights,
    this.recommendation,
    this.isLoading = false,
    this.error,
  });
  
  RecoveryState copyWith({
    double? recoveryScore,
    RecoveryMetrics? metrics,
    RecoveryInsights? insights,
    String? recommendation,
    bool? isLoading,
    String? error,
  }) {
    return RecoveryState(
      recoveryScore: recoveryScore ?? this.recoveryScore,
      metrics: metrics ?? this.metrics,
      insights: insights ?? this.insights,
      recommendation: recommendation ?? this.recommendation,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

/// StateNotifier for managing recovery data
class RecoveryNotifier extends StateNotifier<RecoveryState> {
  final RecoveryService _recoveryService;
  final BodyAnalyticsRepository _bodyAnalyticsRepository;
  
  RecoveryNotifier(this._recoveryService, this._bodyAnalyticsRepository)
      : super(const RecoveryState());
  
  /// Calculate today's recovery score
  Future<void> calculateTodayRecovery() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final today = DateTime.now();
      
      // Get latest body metrics for weight stability
      final latestMetrics = await _bodyAnalyticsRepository.getLatestMetrics();
      
      // Get average weight (last 7 days)
      final last7Days = today.subtract(const Duration(days: 7));
      final recentMetrics = await _bodyAnalyticsRepository.getMetricsHistory(
        start: last7Days,
        end: today,
      );
      
      double? avgWeight;
      if (recentMetrics.isNotEmpty) {
        avgWeight = recentMetrics
            .map((m) => m.weight)
            .reduce((a, b) => a + b) / recentMetrics.length;
      }
      
      // Calculate recovery score
      final recoveryScore = await _recoveryService.calculateRecoveryScore(
        date: today,
        latestMetrics: latestMetrics,
        avgWeight: avgWeight,
      );
      
      // Get recommendation
      final recommendation = _recoveryService.getWorkoutRecommendation(recoveryScore);
      
      // Get recovery metrics
      final healthService = HealthService();
      final metrics = await healthService.fetchRecoveryMetrics(today);
      
      // Get average HRV for comparison
      double? avgHRV;
      if (recentMetrics.isNotEmpty && metrics != null) {
        // Fetch HRV data for last 7 days
        final hrvHistory = <double>[];
        for (var i = 0; i < 7; i++) {
          final date = today.subtract(Duration(days: i));
          final dayMetrics = await healthService.fetchRecoveryMetrics(date);
          if (dayMetrics != null && dayMetrics.hrv > 0) {
            hrvHistory.add(dayMetrics.hrv);
          }
        }
        if (hrvHistory.isNotEmpty) {
          avgHRV = hrvHistory.reduce((a, b) => a + b) / hrvHistory.length;
        }
      }
      
      // Get insights
      final insights = _recoveryService.getRecoveryInsights(
        recoveryScore: recoveryScore,
        metrics: metrics,
        avgHRV: avgHRV,
      );
      
      state = state.copyWith(
        recoveryScore: recoveryScore,
        metrics: metrics,
        insights: insights,
        recommendation: recommendation,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to calculate recovery: $e',
        isLoading: false,
      );
    }
  }
  
  /// Refresh recovery data
  Future<void> refresh() async {
    await calculateTodayRecovery();
  }
  
  /// Check if workout warning should be shown
  bool shouldWarnBeforeWorkout() {
    if (state.recoveryScore == null) return false;
    return _recoveryService.shouldWarnBeforeWorkout(state.recoveryScore!);
  }
  
  /// Get warning message for workout
  String getWorkoutWarning() {
    if (state.recoveryScore == null) return "";
    return _recoveryService.getWorkoutWarningMessage(state.recoveryScore!);
  }
}

/// Provider for RecoveryNotifier
final recoveryProvider = StateNotifierProvider<RecoveryNotifier, RecoveryState>((ref) {
  final recoveryService = ref.watch(recoveryServiceProvider);
  final bodyAnalyticsRepository = ref.watch(bodyAnalyticsRepositoryProvider);
  return RecoveryNotifier(recoveryService, bodyAnalyticsRepository);
});

/// FutureProvider for today's recovery score (auto-calculating)
final todayRecoveryScoreProvider = FutureProvider<double?>((ref) async {
  final notifier = ref.watch(recoveryProvider.notifier);
  await notifier.calculateTodayRecovery();
  return ref.watch(recoveryProvider).recoveryScore;
});

/// Provider to check if HealthKit data is available for recovery
final hasRecoveryDataProvider = FutureProvider<bool>((ref) async {
  try {
    final healthService = HealthService();
    final today = DateTime.now();
    final metrics = await healthService.fetchRecoveryMetrics(today);
    return metrics != null && metrics.sleepHours > 0;
  } catch (e) {
    return false;
  }
});
