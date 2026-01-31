import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/body_analytics/data/services/health_service.dart';

/// Provider for Apple Health initialization status
/// This will request authorization for ALL health data types on first launch
final healthInitializationProvider = FutureProvider<bool>((ref) async {
  final healthService = HealthService();
  
  try {
    print('🍎 Initializing Apple Health connection...');
    
    // Always request authorization to ensure all new data types are included
    // iOS will only show the permission dialog for types not yet authorized
    print('📱 Requesting Apple Health permissions...');
    final granted = await healthService.requestAuthorization();
    
    if (granted) {
      print('✅ Apple Health permissions granted');
    } else {
      print('⚠️ Apple Health permissions denied or unavailable');
    }
    
    return granted;
  } catch (e) {
    print('❌ Error initializing Apple Health: $e');
    return false;
  }
});

/// Provider to force re-authorization (useful after adding new data types)
final healthReauthorizeProvider = FutureProvider.family<bool, void>((ref, _) async {
  final healthService = HealthService();
  return await healthService.reauthorize();
});

/// Provider to check if Apple Health data is available
final healthDataAvailableProvider = FutureProvider<bool>((ref) async {
  final isInitialized = await ref.watch(healthInitializationProvider.future);
  if (!isInitialized) return false;
  
  final healthService = HealthService();
  
  try {
    // Try to fetch latest weight to verify data availability
    final metrics = await healthService.fetchLatestBodyMetrics();
    return metrics != null;
  } catch (e) {
    print('Error checking health data availability: $e');
    return false;
  }
});
