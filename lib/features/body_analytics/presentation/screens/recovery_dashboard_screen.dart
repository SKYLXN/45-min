import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../providers/recovery_provider.dart';
import '../widgets/recovery_score_widget.dart';
import '../widgets/workout_recommendation_card.dart';
import '../widgets/sleep_breakdown_widget.dart';

/// Recovery Dashboard showing today's recovery score, sleep, HRV, and workout recommendations
class RecoveryDashboardScreen extends ConsumerStatefulWidget {
  const RecoveryDashboardScreen({super.key});

  @override
  ConsumerState<RecoveryDashboardScreen> createState() => _RecoveryDashboardScreenState();
}

class _RecoveryDashboardScreenState extends ConsumerState<RecoveryDashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Calculate recovery on screen load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(recoveryProvider.notifier).calculateTodayRecovery();
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final recoveryState = ref.watch(recoveryProvider);
    
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Recovery Dashboard',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
          color: AppColors.textPrimary,
        ),
        actions: [
          IconButton(
            onPressed: () {
              ref.read(recoveryProvider.notifier).refresh();
            },
            icon: const Icon(Icons.refresh),
            color: AppColors.textPrimary,
          ),
        ],
      ),
      body: recoveryState.isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.primaryGreen,
                ),
              ),
            )
          : recoveryState.error != null
              ? _buildError(recoveryState.error!)
              : _buildContent(recoveryState),
    );
  }
  
  Widget _buildError(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load recovery data',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                ref.read(recoveryProvider.notifier).refresh();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: AppColors.backgroundDark,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildContent(RecoveryState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recovery Score (large circular)
          Center(
            child: RecoveryScoreWidget(
              score: state.recoveryScore,
              size: 220,
            ),
          ),
          const SizedBox(height: 32),
          
          // Workout Recommendation Card
          if (state.recommendation != null)
            WorkoutRecommendationCard(
              recommendation: state.recommendation!,
              recoveryScore: state.recoveryScore,
            ),
          const SizedBox(height: 24),
          
          // Insights Section
          if (state.insights != null) ...[
            const Text(
              'Recovery Insights',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Overall Status
            _InsightCard(
              icon: Icons.favorite,
              title: 'Overall Status',
              value: state.insights!.overallStatus,
              color: _getStatusColor(state.recoveryScore ?? 70),
            ),
            const SizedBox(height: 12),
            
            // Sleep Status
            _InsightCard(
              icon: Icons.bedtime,
              title: 'Sleep Quality',
              value: state.insights!.sleepStatus,
              color: AppColors.primaryGold,
            ),
            const SizedBox(height: 12),
            
            // HRV Status
            _InsightCard(
              icon: Icons.monitor_heart,
              title: 'Heart Rate Variability',
              value: state.insights!.hrvStatus,
              color: AppColors.primaryGreen,
            ),
            const SizedBox(height: 24),
            
            // Recommendations
            const Text(
              'Recommendations',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            ...state.insights!.recommendations.map((rec) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _RecommendationTile(recommendation: rec),
            )),
          ],
          
          // Sleep Breakdown (if available)
          if (state.metrics != null && state.metrics!.sleepHours > 0) ...[
            const SizedBox(height: 24),
            SleepBreakdownWidget(
              totalHours: state.metrics!.sleepHours,
              // Note: Sleep stages not available from HealthKit SLEEP_ASLEEP type
              // Would need SLEEP_DEEP, SLEEP_REM data types
            ),
          ],
          
          const SizedBox(height: 32),
          
          // Information note
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBackground.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.borderColor.withOpacity(0.5),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Recovery data is calculated from your Apple Health sleep and HRV measurements. Ensure your Apple Watch is worn during sleep for accurate tracking.',
                    style: TextStyle(
                      color: AppColors.textSecondary.withOpacity(0.8),
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Color _getStatusColor(double score) {
    if (score >= 85) {
      return AppColors.success;
    } else if (score >= 70) {
      return AppColors.primaryGreen;
    } else if (score >= 50) {
      return AppColors.primaryGold;
    } else {
      return AppColors.error;
    }
  }
}

class _InsightCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;
  
  const _InsightCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.borderColor,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecommendationTile extends StatelessWidget {
  final String recommendation;
  
  const _RecommendationTile({required this.recommendation});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 2),
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: AppColors.primaryGreen,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            recommendation,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}
