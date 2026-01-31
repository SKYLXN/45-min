import 'package:flutter_riverpod/flutter_riverpod.dart';
import './health_service.dart';
import '../repositories/body_analytics_repository.dart';
import '../../../../core/models/body_metrics.dart';

/// Service for syncing data between HealthKit and local database
class HealthSyncService {
  final HealthService _healthService;
  final BodyAnalyticsRepository _repository;
  
  HealthSyncService({
    required HealthService healthService,
    required BodyAnalyticsRepository repository,
  })  : _healthService = healthService,
        _repository = repository;
  
  /// Check for new data on app launch and sync
  Future<bool> syncNewData() async {
    try {
      // Check if we have authorization
      final hasAuth = await _healthService.checkAuthorizationStatus();
      if (!hasAuth) {
        print('HealthKit authorization not granted');
        return false;
      }
      
      // Get last sync date from local storage
      final lastMetric = await _repository.getLatestMetrics();
      final lastSyncDate = lastMetric?.timestamp ?? DateTime.now().subtract(const Duration(days: 90));
      
      // Fetch new data from HealthKit
      final now = DateTime.now();
      final healthMetrics = await _healthService.fetchBodyMetrics(
        start: lastSyncDate,
        end: now,
      );
      
      if (healthMetrics.isEmpty) {
        print('No new health data to sync');
        return false;
      }
      
      // Deduplicate entries
      final deduped = _healthService.deduplicateMetrics(healthMetrics);
      
      // Save to local database
      int savedCount = 0;
      for (var metric in deduped) {
        // Check if this date already exists
        final existing = await _repository.getMetricsByDate(metric.timestamp);
        if (existing == null) {
          await _repository.saveBodyMetrics(metric);
          savedCount++;
        } else {
          // Update existing record if BMR has changed (for corrected calculations)
          if ((existing.bmr ?? 0) != (metric.bmr ?? 0)) {
            await _repository.updateBodyMetrics(metric);
            savedCount++;
            print('📝 Updated BMR for ${metric.timestamp.toString().split(' ')[0]}: ${existing.bmr} → ${metric.bmr} kcal');
          }
        }
      }
      
      print('Synced $savedCount new body metrics from HealthKit');
      return savedCount > 0;
    } catch (e) {
      print('Error syncing health data: $e');
      return false;
    }
  }
  
  /// Background sync (when app returns from background)
  Future<void> backgroundSync() async {
    try {
      await syncNewData();
    } catch (e) {
      print('Error during background sync: $e');
    }
  }
  
  /// Manual refresh (pull-to-refresh gesture)
  Future<bool> forceSync() async {
    try {
      // Fetch last 7 days of data to ensure we have recent updates
      final now = DateTime.now();
      final sevenDaysAgo = now.subtract(const Duration(days: 7));
      
      final healthMetrics = await _healthService.fetchBodyMetrics(
        start: sevenDaysAgo,
        end: now,
      );
      
      if (healthMetrics.isEmpty) {
        return false;
      }
      
      // Deduplicate
      final deduped = _healthService.deduplicateMetrics(healthMetrics);
      
      // Update or insert each metric
      for (var metric in deduped) {
        final existing = await _repository.getMetricsByDate(metric.timestamp);
        if (existing != null) {
          // Update if new data is more complete
          await _repository.saveBodyMetrics(metric);
        } else {
          await _repository.saveBodyMetrics(metric);
        }
      }
      
      return true;
    } catch (e) {
      print('Error during force sync: $e');
      return false;
    }
  }
  
  /// Detect new weigh-in and return a stream
  /// Note: This is a polling implementation. For real-time, would need HealthKit background delivery
  Stream<BodyMetrics> watchForNewMetrics() async* {
    BodyMetrics? lastMetric = await _repository.getLatestMetrics();
    
    while (true) {
      await Future.delayed(const Duration(minutes: 5)); // Check every 5 minutes
      
      try {
        final latest = await _healthService.fetchLatestBodyMetrics();
        
        if (latest != null && 
            (lastMetric == null || latest.timestamp.isAfter(lastMetric.timestamp))) {
          lastMetric = latest;
          yield latest;
        }
      } catch (e) {
        print('Error watching for new metrics: $e');
      }
    }
  }
  
  /// Handle duplicate entries from multiple sources
  List<BodyMetrics> deduplicateMetrics(List<BodyMetrics> raw) {
    return _healthService.deduplicateMetrics(raw);
  }
  
  /// Fetch and sync recovery data for today
  Future<RecoveryMetrics?> syncTodayRecoveryData() async {
    try {
      final today = DateTime.now();
      final recoveryData = await _healthService.fetchRecoveryMetrics(today);
      
      // Could store this in a separate table if needed
      // For now, just return it
      return recoveryData;
    } catch (e) {
      print('Error syncing recovery data: $e');
      return null;
    }
  }
  
  /// Sync active calories for today
  Future<double> syncTodayActiveCalories() async {
    try {
      final today = DateTime.now();
      return await _healthService.fetchActiveCalories(today);
    } catch (e) {
      print('Error syncing active calories: $e');
      return 0.0;
    }
  }
}

/// Provider for HealthSyncService (duplicate - use one in health_sync_provider.dart)
// final healthSyncServiceProvider = Provider<HealthSyncService>((ref) {
//   final healthService = HealthService();
//   final repository = ref.watch(bodyAnalyticsRepositoryProvider);
//   
//   return HealthSyncService(
//     healthService: healthService,
//     repository: repository,
//   );
// });
