import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/body_analytics_repository.dart';
import '../../../core/models/body_metrics.dart';
import '../../../core/models/segmental_analysis.dart';

// ============================================================================
// Data Providers
// ============================================================================

/// Provider for latest body metrics
final latestBodyMetricsProvider = FutureProvider<BodyMetrics?>((ref) async {
  final repository = ref.watch(bodyAnalyticsRepositoryProvider);
  return await repository.getLatestMetrics();
});

/// Provider for all body metrics history
final allBodyMetricsProvider = FutureProvider<List<BodyMetrics>>((ref) async {
  final repository = ref.watch(bodyAnalyticsRepositoryProvider);
  return await repository.getAllMetrics();
});

/// Provider for latest segmental analysis
final latestSegmentalAnalysisProvider = FutureProvider<SegmentalAnalysis?>((ref) async {
  final repository = ref.watch(bodyAnalyticsRepositoryProvider);
  return await repository.getLatestSegmentalAnalysis();
});

/// Provider for metrics history in date range
final metricsHistoryProvider = FutureProvider.family<List<BodyMetrics>, DateRange>(
  (ref, dateRange) async {
    final repository = ref.watch(bodyAnalyticsRepositoryProvider);
    return await repository.getMetricsHistory(
      start: dateRange.start,
      end: dateRange.end,
    );
  },
);

/// Provider for specific metric progression data
final metricProgressionProvider = FutureProvider.family<List<Map<String, dynamic>>, String>(
  (ref, metricField) async {
    final repository = ref.watch(bodyAnalyticsRepositoryProvider);
    return await repository.getProgressionData(metricField: metricField);
  },
);

/// Provider for combined latest data (metrics + segmental)
final latestCombinedDataProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final repository = ref.watch(bodyAnalyticsRepositoryProvider);
  return await repository.getLatestCombinedData();
});

// ============================================================================
// State Notifier for Body Analytics Management
// ============================================================================

/// State for body analytics operations
class BodyAnalyticsState {
  final List<BodyMetrics> metrics;
  final BodyMetrics? latestMetrics;
  final SegmentalAnalysis? latestSegmental;
  final bool isLoading;
  final String? error;

  const BodyAnalyticsState({
    this.metrics = const [],
    this.latestMetrics,
    this.latestSegmental,
    this.isLoading = false,
    this.error,
  });

  BodyAnalyticsState copyWith({
    List<BodyMetrics>? metrics,
    BodyMetrics? latestMetrics,
    SegmentalAnalysis? latestSegmental,
    bool? isLoading,
    String? error,
  }) {
    return BodyAnalyticsState(
      metrics: metrics ?? this.metrics,
      latestMetrics: latestMetrics ?? this.latestMetrics,
      latestSegmental: latestSegmental ?? this.latestSegmental,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier for managing body analytics state
class BodyAnalyticsNotifier extends StateNotifier<BodyAnalyticsState> {
  final BodyAnalyticsRepository _repository;

  BodyAnalyticsNotifier(this._repository) : super(const BodyAnalyticsState());

  /// Load all metrics
  Future<void> loadMetrics() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final metrics = await _repository.getAllMetrics();
      final latest = await _repository.getLatestMetrics();
      final segmental = await _repository.getLatestSegmentalAnalysis();

      state = state.copyWith(
        metrics: metrics,
        latestMetrics: latest,
        latestSegmental: segmental,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load metrics: $e',
      );
    }
  }

  /// Save new body metrics
  Future<void> saveMetrics(BodyMetrics metrics) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.saveBodyMetrics(metrics);
      await loadMetrics(); // Reload after save
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to save metrics: $e',
      );
    }
  }

  /// Alias for saveMetrics (for consistency with analytics_dashboard_screen)
  Future<void> saveBodyMetrics(BodyMetrics metrics) => saveMetrics(metrics);

  /// Save body metrics with segmental analysis
  Future<void> saveMetricsWithSegmental({
    required BodyMetrics metrics,
    required SegmentalAnalysis segmental,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.saveBodyMetricsWithSegmental(
        metrics: metrics,
        segmental: segmental,
      );
      await loadMetrics(); // Reload after save
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to save data: $e',
      );
    }
  }

  /// Delete metrics by ID
  Future<void> deleteMetrics(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.deleteMetrics(id);
      await loadMetrics(); // Reload after delete
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to delete metrics: $e',
      );
    }
  }

  /// Get chart data for specific metric
  Future<List<Map<String, dynamic>>> getChartData(String metricField) async {
    try {
      return await _repository.getProgressionData(metricField: metricField);
    } catch (e) {
      state = state.copyWith(error: 'Failed to get chart data: $e');
      return [];
    }
  }
}

/// Provider for body analytics state management
final bodyAnalyticsProvider = StateNotifierProvider<BodyAnalyticsNotifier, BodyAnalyticsState>(
  (ref) {
    final repository = ref.watch(bodyAnalyticsRepositoryProvider);
    return BodyAnalyticsNotifier(repository);
  },
);

// ============================================================================
// Helper Classes
// ============================================================================

/// Date range for filtering metrics
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
