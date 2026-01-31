import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:health/health.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/repositories/body_analytics_repository.dart';
import '../../providers/body_analytics_provider.dart';
import '../../providers/recovery_provider.dart';
import '../widgets/health_permission_card.dart';
import '../widgets/metric_card_auto.dart';
import '../widgets/sync_status_indicator.dart';
import '../widgets/recovery_score_widget.dart';
import 'health_sync_setup_screen.dart';
import 'recovery_dashboard_screen.dart';
import 'progress_chart_screen.dart';
import '../../../body_analytics/data/services/health_service.dart';

/// Enhanced Analytics Dashboard with automatic Apple Health sync
class AnalyticsDashboardScreen extends ConsumerStatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  ConsumerState<AnalyticsDashboardScreen> createState() => _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends ConsumerState<AnalyticsDashboardScreen> {
  final _healthService = HealthService();
  bool _isCheckingPermission = true;
  bool _hasPermission = false;
  bool _isSyncing = false;
  DateTime? _lastSyncTime;
  String _selectedTimePeriod = '1 week';
  Future<HeartRateMetrics?>? _cachedHeartMetrics;

  @override
  void initState() {
    super.initState();
    _checkHealthKitPermission();
    // Load metrics immediately when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bodyAnalyticsProvider.notifier).loadMetrics();
    });
  }
  
  Future<void> _checkHealthKitPermission() async {
    setState(() => _isCheckingPermission = true);
    
    try {
      final hasPermission = await _healthService.checkAuthorizationStatus();
      setState(() {
        _hasPermission = hasPermission;
        _isCheckingPermission = false;
      });
      
      // Always load existing local data first
      ref.read(bodyAnalyticsProvider.notifier).loadMetrics();
      
      if (hasPermission) {
        // Then sync from HealthKit (this will update the provider if new data is found)
        _syncFromHealthKit();
        // Also calculate recovery
        ref.read(recoveryProvider.notifier).calculateTodayRecovery();
      }
    } catch (e) {
      setState(() => _isCheckingPermission = false);
      // Still try to load local data even if permission check fails
      ref.read(bodyAnalyticsProvider.notifier).loadMetrics();
    }
  }
  
  Future<void> _syncFromHealthKit() async {
    setState(() => _isSyncing = true);
    
    try {
      // Check and request authorization for heart rate data if needed
      final hasHeartRatePermissions = await _healthService.hasPermissions([
        HealthDataType.HEART_RATE,
        HealthDataType.WALKING_HEART_RATE,
        HealthDataType.RESTING_HEART_RATE,
        // Note: VO2_MAX not available in Flutter health package v13.3.0 yet
      ]);
      
      if (!hasHeartRatePermissions) {
        print('🔄 Requesting heart rate data authorization...');
        await _healthService.requestAuthorization();
      }
      
      // Comprehensive sync: fetch last 30 days to update any records with corrected BMR
      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));
      
      final historicalMetrics = await _healthService.fetchBodyMetrics(
        start: thirtyDaysAgo,
        end: now,
      );
      
      if (historicalMetrics.isNotEmpty) {
        // Save/update all metrics via provider
        for (var metric in historicalMetrics) {
          // Check if exists
          final existing = await ref.read(bodyAnalyticsRepositoryProvider).getMetricsByDate(metric.timestamp);
          if (existing == null) {
            await ref.read(bodyAnalyticsProvider.notifier).saveBodyMetrics(metric);
          } else if ((existing.bmr ?? 0) != (metric.bmr ?? 0)) {
            // Update if BMR changed
            await ref.read(bodyAnalyticsRepositoryProvider).updateBodyMetrics(metric);
          }
        }
        
        // Also fetch and save the latest single record
        final latestMetrics = await _healthService.fetchLatestBodyMetrics();
        if (latestMetrics != null) {
          await ref.read(bodyAnalyticsProvider.notifier).saveBodyMetrics(latestMetrics);
        }
        
        // Refresh providers to reload updated data
        ref.invalidate(latestBodyMetricsProvider);
        ref.invalidate(allBodyMetricsProvider);
        
        // Refresh cached heart metrics
        setState(() {
          _cachedHeartMetrics = null;
        });
        
        setState(() {
          _lastSyncTime = DateTime.now();
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Refreshed from Apple Health'),
              backgroundColor: AppColors.success,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() => _isSyncing = false);
    }
  }
  
  Future<void> _navigateToSetup() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const HealthSyncSetupScreen(),
      ),
    );
    
    if (result == true) {
      // Permission granted, refresh
      _checkHealthKitPermission();
    }
  }
  
  void _showTimePeriodSelector() {
    final periods = ['1 week', '1 month', '3 months', 'All time'];
    
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Select Time Period',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ...periods.map((period) => ListTile(
                leading: Icon(
                  _selectedTimePeriod == period
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: _selectedTimePeriod == period
                      ? AppColors.primaryGreen
                      : AppColors.textSecondary,
                ),
                title: Text(
                  period,
                  style: TextStyle(
                    color: _selectedTimePeriod == period
                        ? AppColors.primaryGreen
                        : AppColors.textPrimary,
                    fontWeight: _selectedTimePeriod == period
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
                onTap: () {
                  setState(() {
                    _selectedTimePeriod = period;
                  });
                  Navigator.pop(context);
                  // Reload data with new time period
                  ref.read(bodyAnalyticsProvider.notifier).loadMetrics();
                },
              )),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bodyAnalyticsState = ref.watch(bodyAnalyticsProvider);
    final recoveryState = ref.watch(recoveryProvider);
    
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.go('/'),
        ),
        title: const Text(
          'Body Analytics',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _showTimePeriodSelector,
            icon: const Icon(Icons.calendar_today),
            color: AppColors.textPrimary,
          ),
        ],
      ),
      body: _isCheckingPermission
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.primaryGreen,
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: () async {
                if (_hasPermission) {
                  await _syncFromHealthKit();
                  await ref.read(recoveryProvider.notifier).refresh();
                }
              },
              color: AppColors.primaryGreen,
              backgroundColor: AppColors.cardBackground,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Time Period Indicator
                    if (_hasPermission)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Showing: $_selectedTimePeriod',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    // Health Permission Card
                    if (!_hasPermission)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: HealthPermissionCard(
                          isGranted: _hasPermission,
                          onRequestPermission: _navigateToSetup,
                        ),
                      ),
                    
                    // Sync Status
                    if (_hasPermission)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: SyncStatusIndicator(
                          lastSyncTime: _lastSyncTime,
                          isSyncing: _isSyncing,
                          onRefresh: _syncFromHealthKit,
                        ),
                      ),
                    
                    // Recovery Score Card (clickable)
                    if (_hasPermission && recoveryState.recoveryScore != null)
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const RecoveryDashboardScreen(),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          margin: const EdgeInsets.only(bottom: 24),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primaryGreen.withOpacity(0.15),
                                AppColors.primaryGreen.withOpacity(0.05),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.primaryGreen.withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              RecoveryScoreWidget(
                                score: recoveryState.recoveryScore,
                                size: 100,
                              ),
                              const SizedBox(width: 24),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Today\'s Recovery',
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      recoveryState.recommendation ?? 'Loading...',
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 14,
                                        height: 1.4,
                                      ),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        const Text(
                                          'View Details',
                                          style: TextStyle(
                                            color: AppColors.primaryGreen,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(
                                          Icons.arrow_forward,
                                          color: AppColors.primaryGreen,
                                          size: 16,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    
                    // Key Metrics Grid
                    const Text(
                      'Key Metrics',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    bodyAnalyticsState.isLoading
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32.0),
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.primaryGreen,
                                ),
                              ),
                            ),
                          )
                        : bodyAnalyticsState.latestMetrics == null
                            ? _buildNoDataCard()
                            : _buildMetricsGrid(bodyAnalyticsState, recoveryState),
                    
                    // Progress Charts Info
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primaryGreen.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.touch_app,
                            color: AppColors.primaryGreen,
                            size: 24,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'View Progress Charts',
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Tap any metric card above to view detailed progress charts',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
  
  Widget _buildNoDataCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.borderColor,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 64,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Data Available',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _hasPermission
                ? 'Weigh yourself on a smart scale synced to Apple Health'
                : 'Connect to Apple Health to see your body metrics',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildMetricsGrid(BodyAnalyticsState state, RecoveryState recoveryState) {
    final metrics = state.latestMetrics!;
    
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: FutureBuilder<double?>(
                future: _calculateProgress('weight', metrics.weight),
                builder: (context, snapshot) {
                  return MetricCardAuto(
                    title: 'Weight',
                    value: metrics.weight.toStringAsFixed(1),
                    unit: 'kg',
                    icon: Icons.monitor_weight,
                    iconColor: AppColors.primaryGreen,
                    change: snapshot.data,
                    isAutoSynced: _hasPermission,
                    lastUpdate: metrics.timestamp,
                    onTap: () => _navigateToProgressChart(
                      'weight',
                      'Weight',
                      'kg',
                      AppColors.primaryGreen,
                      Icons.monitor_weight,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FutureBuilder<double?>(
                future: _calculateProgress('bodyfat', metrics.bodyFat),
                builder: (context, snapshot) {
                  return MetricCardAuto(
                    title: 'Body Fat',
                    value: metrics.bodyFat.toStringAsFixed(1),
                    unit: '%',
                    icon: Icons.trending_down,
                    iconColor: AppColors.primaryGold,
                    change: snapshot.data,
                    isAutoSynced: _hasPermission,
                    lastUpdate: metrics.timestamp,
                    onTap: () => _navigateToProgressChart(
                      'bodyfat',
                      'Body Fat',
                      '%',
                      AppColors.primaryGold,
                      Icons.trending_down,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: FutureBuilder<double?>(
                future: _calculateProgress('skeletalmuscle', metrics.skeletalMuscle),
                builder: (context, snapshot) {
                  return MetricCardAuto(
                    title: 'Skeletal Muscle',
                    value: metrics.skeletalMuscle.toStringAsFixed(1),
                    unit: 'kg',
                    icon: Icons.fitness_center,
                    iconColor: const Color(0xFF8B5CF6), // Purple
                    change: snapshot.data,
                    isAutoSynced: _hasPermission,
                    lastUpdate: metrics.timestamp,
                    onTap: () => _navigateToProgressChart(
                      'skeletalmuscle',
                      'Skeletal Muscle',
                      'kg',
                      const Color(0xFF8B5CF6),
                      Icons.fitness_center,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FutureBuilder<double?>(
                future: _calculateProgress('bmi', metrics.bmi),
                builder: (context, snapshot) {
                  return MetricCardAuto(
                    title: 'BMI',
                    value: metrics.bmi.toStringAsFixed(1),
                    unit: '',
                    icon: Icons.analytics,
                    iconColor: const Color(0xFF3B82F6), // Blue
                    subtitle: _getBMICategory(metrics.bmi),
                    change: snapshot.data,
                    isAutoSynced: _hasPermission,
                    lastUpdate: metrics.timestamp,
                    onTap: () => _navigateToProgressChart(
                      'bmi',
                      'BMI',
                      '',
                      const Color(0xFF3B82F6),
                      Icons.analytics,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: FutureBuilder<double?>(
                future: _calculateProgress('bmr', metrics.bmr.toDouble()),
                builder: (context, snapshot) {
                  return MetricCardAuto(
                    title: 'BMR',
                    value: metrics.bmr.toString(),
                    unit: 'kcal',
                    icon: Icons.local_fire_department,
                    iconColor: const Color(0xFFEF4444), // Red
                    subtitle: 'per day',
                    change: snapshot.data,
                    isAutoSynced: _hasPermission,
                    lastUpdate: metrics.timestamp,
                    onTap: () => _navigateToProgressChart(
                      'bmr',
                      'BMR',
                      'kcal',
                      const Color(0xFFEF4444),
                      Icons.local_fire_department,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: MetricCardAuto(
                title: 'Sleep',
                value: recoveryState.metrics?.sleepHours.toStringAsFixed(1) ?? '--',
                unit: 'hours',
                icon: Icons.bedtime,
                iconColor: AppColors.primaryGold,
                subtitle: 'last night',
                isAutoSynced: _hasPermission,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const RecoveryDashboardScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        // Heart Metrics Section
        Row(
          children: [
            const Icon(
              Icons.favorite,
              color: AppColors.primaryGold,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Heart Metrics',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        FutureBuilder<HeartRateMetrics?>(
          future: _cachedHeartMetrics ?? (_cachedHeartMetrics = _healthService.fetchHeartRateMetrics(DateTime.now())),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return _buildHeartMetricsLoading();
            }
            
            final heartMetrics = snapshot.data!;
            return _buildHeartMetricsGrid(heartMetrics, recoveryState);
          },
        ),
      ],
    );
  }
  
  void _navigateToProgressChart(
    String metricName,
    String displayName,
    String unit,
    Color color,
    IconData icon,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProgressChartScreen(
          metricName: metricName,
          metricDisplayName: displayName,
          unit: unit,
          color: color,
          icon: icon,
        ),
      ),
    );
  }
  
  Widget _buildHeartMetricsLoading() {
    return Column(
      children: [
        Row(
          children: List.generate(2, (index) => 
            Expanded(
              child: Container(
                margin: EdgeInsets.only(right: index == 0 ? 12 : 0),
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryGreen,
                    strokeWidth: 2,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: List.generate(2, (index) => 
            Expanded(
              child: Container(
                margin: EdgeInsets.only(right: index == 0 ? 12 : 0),
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryGreen,
                    strokeWidth: 2,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildHeartMetricsGrid(HeartRateMetrics heartMetrics, RecoveryState recoveryState) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: MetricCardAuto(
                title: 'Heart Rate',
                value: heartMetrics.averageHeartRate.toStringAsFixed(0),
                unit: 'bpm',
                icon: Icons.favorite,
                iconColor: const Color(0xFFEF4444), // Red
                subtitle: 'average',
                isAutoSynced: _hasPermission,
                onTap: () => _navigateToProgressChart(
                  'heartrate',
                  'Heart Rate',
                  'bpm',
                  const Color(0xFFEF4444),
                  Icons.favorite,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: MetricCardAuto(
                title: 'Walking HR',
                value: heartMetrics.walkingHeartRate.toStringAsFixed(0),
                unit: 'bpm',
                icon: Icons.directions_walk,
                iconColor: const Color(0xFF10B981), // Green
                subtitle: 'walking avg',
                isAutoSynced: _hasPermission,
                onTap: () => _navigateToProgressChart(
                  'walkinghr',
                  'Walking Heart Rate',
                  'bpm',
                  const Color(0xFF10B981),
                  Icons.directions_walk,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: MetricCardAuto(
                title: 'Resting HR',
                value: (recoveryState.metrics?.restingHR ?? 67).toStringAsFixed(0),
                unit: 'bpm',
                icon: Icons.bedtime,
                iconColor: const Color(0xFF8B5CF6), // Purple
                subtitle: 'at rest',
                isAutoSynced: _hasPermission,
                onTap: () => _navigateToProgressChart(
                  'restinghr',
                  'Resting Heart Rate',
                  'bpm',
                  const Color(0xFF8B5CF6),
                  Icons.bedtime,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: MetricCardAuto(
                title: 'VO2 Max',
                value: heartMetrics.vo2Max.toStringAsFixed(1),
                unit: 'ml/kg/min',
                icon: Icons.fitness_center,
                iconColor: const Color(0xFF3B82F6), // Blue
                subtitle: 'cardio fitness',
                isAutoSynced: _hasPermission,
                onTap: () => _navigateToProgressChart(
                  'vo2max',
                  'VO2 Max',
                  'ml/kg/min',
                  const Color(0xFF3B82F6),
                  Icons.fitness_center,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _getBMICategory(double bmi) {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }
  
  /// Calculate progress percentage for a metric over the selected time period
  Future<double?> _calculateProgress(String metricName, double currentValue) async {
    try {
      final repository = ref.read(bodyAnalyticsRepositoryProvider);
      final now = DateTime.now();
      DateTime startDate;
      
      // Calculate start date based on selected time period
      switch (_selectedTimePeriod) {
        case '1 week':
          startDate = now.subtract(const Duration(days: 7));
          break;
        case '1 month':
          startDate = now.subtract(const Duration(days: 30));
          break;
        case '3 months':
          startDate = now.subtract(const Duration(days: 90));
          break;
        case 'All time':
          startDate = now.subtract(const Duration(days: 365));
          break;
        default:
          startDate = now.subtract(const Duration(days: 7));
      }
      
      // Get historical metrics
      final historical = await repository.getMetricsHistory(
        start: startDate,
        end: now,
      );
      
      if (historical.length < 2) return null;
      
      // Get oldest value in the period
      final oldestMetric = historical.last;
      double oldValue;
      
      switch (metricName.toLowerCase()) {
        case 'weight':
          oldValue = oldestMetric.weight;
          break;
        case 'bodyfat':
          oldValue = oldestMetric.bodyFat;
          break;
        case 'skeletalmuscle':
          oldValue = oldestMetric.skeletalMuscle;
          break;
        case 'bmi':
          oldValue = oldestMetric.bmi;
          break;
        case 'bmr':
          oldValue = oldestMetric.bmr.toDouble();
          break;
        default:
          return null;
      }
      
      if (oldValue == 0) return null;
      
      // Calculate percentage change
      final change = ((currentValue - oldValue) / oldValue) * 100;
      return change;
    } catch (e) {
      print('Error calculating progress for $metricName: $e');
      return null;
    }
  }
}
