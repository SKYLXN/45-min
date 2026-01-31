import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/body_analytics_repository.dart';
import '../data/services/health_service.dart';
import '../data/services/health_sync_service.dart';
import '../data/repositories/body_analytics_repository.dart';
import 'body_analytics_provider.dart';

/// State for HealthKit sync status
class HealthSyncState {
  final bool isSyncing;
  final DateTime? lastSyncTime;
  final String? syncError;
  final bool permissionGranted;
  final bool isCheckingPermission;
  
  const HealthSyncState({
    this.isSyncing = false,
    this.lastSyncTime,
    this.syncError,
    this.permissionGranted = false,
    this.isCheckingPermission = false,
  });
  
  HealthSyncState copyWith({
    bool? isSyncing,
    DateTime? lastSyncTime,
    String? syncError,
    bool? permissionGranted,
    bool? isCheckingPermission,
  }) {
    return HealthSyncState(
      isSyncing: isSyncing ?? this.isSyncing,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      syncError: syncError,
      permissionGranted: permissionGranted ?? this.permissionGranted,
      isCheckingPermission: isCheckingPermission ?? this.isCheckingPermission,
    );
  }
  
  /// Clear error state
  HealthSyncState clearError() {
    return HealthSyncState(
      isSyncing: isSyncing,
      lastSyncTime: lastSyncTime,
      syncError: null,
      permissionGranted: permissionGranted,
      isCheckingPermission: isCheckingPermission,
    );
  }
}

/// StateNotifier for managing HealthKit sync operations
class HealthSyncNotifier extends StateNotifier<HealthSyncState> {
  final HealthService _healthService;
  final HealthSyncService _syncService;
  final BodyAnalyticsRepository _bodyAnalyticsRepository;
  
  HealthSyncNotifier(
    this._healthService,
    this._syncService,
    this._bodyAnalyticsRepository,
  ) : super(const HealthSyncState());
  
  /// Check if HealthKit permissions are granted
  Future<void> checkPermissions() async {
    state = state.copyWith(isCheckingPermission: true);
    
    try {
      final granted = await _healthService.checkAuthorizationStatus();
      state = state.copyWith(
        permissionGranted: granted,
        isCheckingPermission: false,
      );
    } catch (e) {
      state = state.copyWith(
        syncError: 'Failed to check permissions: $e',
        isCheckingPermission: false,
      );
    }
  }
  
  /// Request HealthKit permissions
  Future<bool> requestPermissions() async {
    state = state.copyWith(isCheckingPermission: true, syncError: null);
    
    try {
      final granted = await _healthService.requestAuthorization();
      state = state.copyWith(
        permissionGranted: granted,
        isCheckingPermission: false,
      );
      
      // If granted, perform initial sync
      if (granted) {
        await syncNow();
      }
      
      return granted;
    } catch (e) {
      state = state.copyWith(
        syncError: 'Failed to request permissions: $e',
        isCheckingPermission: false,
      );
      return false;
    }
  }
  
  /// Manually trigger a sync with HealthKit
  Future<void> syncNow() async {
    if (state.isSyncing) return; // Prevent concurrent syncs
    
    state = state.copyWith(isSyncing: true, syncError: null);
    
    try {
      // Check permission first
      final hasPermission = await _healthService.checkAuthorizationStatus();
      if (!hasPermission) {
        state = state.copyWith(
          syncError: 'HealthKit permission not granted',
          isSyncing: false,
          permissionGranted: false,
        );
        return;
      }
      
      // Perform sync
      await _syncService.syncNewData();
      
      state = state.copyWith(
        lastSyncTime: DateTime.now(),
        isSyncing: false,
        permissionGranted: true,
      );
    } catch (e) {
      state = state.copyWith(
        syncError: 'Sync failed: $e',
        isSyncing: false,
      );
    }
  }
  
  /// Background sync - called when app resumes from background
  Future<void> backgroundSync() async {
    if (!state.permissionGranted) return;
    if (state.isSyncing) return;
    
    // Check if last sync was more than 5 minutes ago
    if (state.lastSyncTime != null) {
      final difference = DateTime.now().difference(state.lastSyncTime!);
      if (difference.inMinutes < 5) {
        return; // Skip sync if recent
      }
    }
    
    await syncNow();
  }
  
  /// Enable background sync (setup listeners for app lifecycle)
  /// Note: Actual implementation would use AppLifecycleState listener
  void enableBackgroundSync() {
    // TODO: Implement AppLifecycleState listener
    // This would listen for AppLifecycleState.resumed and trigger backgroundSync()
    // For now, this is a placeholder
  }
  
  /// Force sync with specific date range (for manual refresh)
  Future<void> forceSyncWithRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (state.isSyncing) return;
    
    state = state.copyWith(isSyncing: true, syncError: null);
    
    try {
      final hasPermission = await _healthService.checkAuthorizationStatus();
      if (!hasPermission) {
        state = state.copyWith(
          syncError: 'HealthKit permission not granted',
          isSyncing: false,
          permissionGranted: false,
        );
        return;
      }
      
      // Fetch metrics for date range
      final metrics = await _healthService.fetchBodyMetrics(
        start: startDate,
        end: endDate,
      );
      
      // Save to local database
      for (var metric in metrics) {
        await _bodyAnalyticsRepository.saveBodyMetrics(metric);
      }
      
      state = state.copyWith(
        lastSyncTime: DateTime.now(),
        isSyncing: false,
        permissionGranted: true,
      );
    } catch (e) {
      state = state.copyWith(
        syncError: 'Force sync failed: $e',
        isSyncing: false,
      );
    }
  }
  
  /// Clear sync error
  void clearError() {
    state = state.clearError();
  }
  
  /// Get time since last sync (in minutes)
  int? getMinutesSinceLastSync() {
    if (state.lastSyncTime == null) return null;
    return DateTime.now().difference(state.lastSyncTime!).inMinutes;
  }
  
  /// Check if sync is needed (based on time threshold)
  bool shouldSync({int minutesThreshold = 30}) {
    if (state.lastSyncTime == null) return true;
    final minutesSince = getMinutesSinceLastSync();
    return minutesSince != null && minutesSince >= minutesThreshold;
  }
}

/// Provider for HealthService
final healthServiceProvider = Provider<HealthService>((ref) {
  return HealthService();
});

/// Provider for HealthSyncService
final healthSyncServiceProvider = Provider<HealthSyncService>((ref) {
  final healthService = ref.watch(healthServiceProvider);
  final repository = ref.watch(bodyAnalyticsRepositoryProvider);
  return HealthSyncService(
    healthService: healthService,
    repository: repository,
  );
});

/// Provider for HealthSyncNotifier
final healthSyncProvider = StateNotifierProvider<HealthSyncNotifier, HealthSyncState>((ref) {
  final healthService = ref.watch(healthServiceProvider);
  final syncService = ref.watch(healthSyncServiceProvider);
  final bodyAnalyticsRepository = ref.watch(bodyAnalyticsRepositoryProvider);
  
  return HealthSyncNotifier(
    healthService,
    syncService,
    bodyAnalyticsRepository,
  );
});

/// FutureProvider to check permissions on app launch
final healthPermissionStatusProvider = FutureProvider<bool>((ref) async {
  final healthService = ref.watch(healthServiceProvider);
  return await healthService.checkAuthorizationStatus();
});

/// Provider to get formatted last sync time string
final lastSyncTimeStringProvider = Provider<String>((ref) {
  final syncState = ref.watch(healthSyncProvider);
  
  if (syncState.lastSyncTime == null) {
    return 'Never synced';
  }
  
  final now = DateTime.now();
  final difference = now.difference(syncState.lastSyncTime!);
  
  if (difference.inMinutes < 1) {
    return 'Just now';
  } else if (difference.inMinutes < 60) {
    return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
  } else if (difference.inHours < 24) {
    return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
  } else {
    return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
  }
});
