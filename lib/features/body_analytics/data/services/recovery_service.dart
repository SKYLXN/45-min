import '../../../../core/models/body_metrics.dart';
import '../../../workout_mode/data/models/workout_session.dart';
import 'health_service.dart';

/// Service for calculating recovery scores and adjusting workout intensity
/// based on sleep, HRV, and body composition data from Apple HealthKit
class RecoveryService {
  final HealthService _healthService;
  
  RecoveryService(this._healthService);
  
  /// Calculate daily recovery score (0-100) based on sleep, HRV, and weight stability
  /// 
  /// Formula: Score = (Sleep Quality * 0.4) + (HRV Status * 0.4) + (Weight Stability * 0.2)
  /// 
  /// Higher scores indicate better recovery and readiness for intense training
  Future<double> calculateRecoveryScore({
    required DateTime date,
    BodyMetrics? latestMetrics,
    double? avgWeight,
  }) async {
    try {
      // Fetch recovery metrics from HealthKit
      final recoveryMetrics = await _healthService.fetchRecoveryMetrics(date);
      
      if (recoveryMetrics == null) {
        // No data available - return moderate score
        return 70.0;
      }
      
      // Sleep Component (40% weight)
      final sleepScore = _calculateSleepScore(recoveryMetrics.sleepHours);
      
      // HRV Component (40% weight) - Most important for nervous system recovery
      final hrvScore = _calculateHRVScore(
        recoveryMetrics.hrv,
        recoveryMetrics.restingHR,
      );
      
      // Weight Stability (20% weight) - Rapid loss indicates overtraining
      final weightScore = _calculateWeightStability(
        latestMetrics,
        avgWeight ?? latestMetrics?.weight ?? 0.0,
      );
      
      final totalScore = (sleepScore * 0.4) + (hrvScore * 0.4) + (weightScore * 0.2);
      
      // Clamp between 0-100
      return totalScore.clamp(0.0, 100.0);
    } catch (e) {
      print('Error calculating recovery score: $e');
      return 70.0; // Default moderate score on error
    }
  }
  
  /// Calculate sleep quality score (0-100)
  /// Based on total sleep duration
  double _calculateSleepScore(double sleepHours) {
    if (sleepHours >= 8.0) {
      return 100.0; // Excellent recovery
    } else if (sleepHours >= 7.0) {
      return 85.0; // Good recovery
    } else if (sleepHours >= 6.0) {
      return 65.0; // Moderate recovery
    } else if (sleepHours >= 5.0) {
      return 45.0; // Poor recovery
    } else {
      return 25.0; // Critical - recommend rest day
    }
  }
  
  /// Calculate HRV-based recovery score (0-100)
  /// HRV (Heart Rate Variability) is the gold standard for recovery assessment
  /// 
  /// Higher HRV = Better recovery
  /// Lower resting HR = Better fitness/recovery
  double _calculateHRVScore(double hrv, double restingHR) {
    // HRV baseline varies by individual, but general guidelines:
    // Elite athletes: 70-100ms
    // Fit individuals: 50-70ms
    // Average: 30-50ms
    // Overtrained: <30ms
    
    double hrvScore = 0.0;
    
    if (hrv >= 70) {
      hrvScore = 100.0; // Excellent nervous system recovery
    } else if (hrv >= 50) {
      hrvScore = 80.0; // Good recovery
    } else if (hrv >= 30) {
      hrvScore = 60.0; // Moderate recovery
    } else if (hrv >= 20) {
      hrvScore = 40.0; // Poor recovery
    } else {
      hrvScore = 20.0; // Very poor - potential overtraining
    }
    
    // Resting HR modifier (lower is better)
    // Typical ranges: 60-100 bpm (general), 40-60 bpm (athletes)
    double rhScore = 0.0;
    
    if (restingHR <= 50) {
      rhScore = 100.0; // Excellent cardiovascular fitness
    } else if (restingHR <= 60) {
      rhScore = 85.0; // Good fitness
    } else if (restingHR <= 70) {
      rhScore = 70.0; // Average fitness
    } else if (restingHR <= 80) {
      rhScore = 55.0; // Below average
    } else {
      rhScore = 40.0; // Consider medical check-up if consistently high
    }
    
    // Weighted average: HRV is more important (70%), RHR is supporting (30%)
    return (hrvScore * 0.7) + (rhScore * 0.3);
  }
  
  /// Calculate weight stability score (0-100)
  /// Rapid weight loss can indicate overtraining or inadequate nutrition
  double _calculateWeightStability(BodyMetrics? latestMetrics, double avgWeight) {
    if (latestMetrics == null || avgWeight == 0) {
      return 100.0; // No data - assume stable
    }
    
    final currentWeight = latestMetrics.weight;
    final weightChange = ((currentWeight - avgWeight) / avgWeight) * 100;
    
    // Weight stability thresholds (weekly change %)
    if (weightChange.abs() <= 0.5) {
      return 100.0; // Stable weight - excellent
    } else if (weightChange.abs() <= 1.0) {
      return 90.0; // Minor fluctuation - normal
    } else if (weightChange.abs() <= 2.0) {
      return 75.0; // Moderate change - monitor
    } else if (weightChange.abs() <= 3.0) {
      return 55.0; // Significant change - check nutrition
    } else {
      return 30.0; // Rapid change - potential overtraining or diet issue
    }
  }
  
  /// Get smart workout recommendation based on recovery score
  String getWorkoutRecommendation(double recoveryScore) {
    if (recoveryScore < 40) {
      return "🛑 Critical recovery needed. Take a rest day or do light stretching/walking only.";
    } else if (recoveryScore < 50) {
      return "⚠️ Low recovery detected. Consider a rest day or very light mobility work.";
    } else if (recoveryScore < 60) {
      return "😐 Below-average recovery. Reduce intensity by 20-30% and cut volume by 1 set per exercise.";
    } else if (recoveryScore < 70) {
      return "😐 Moderate recovery. Reduce intensity by 10-15% today and focus on technique.";
    } else if (recoveryScore < 85) {
      return "👍 Good recovery. Proceed with planned workout at normal intensity.";
    } else {
      return "💪 Excellent recovery! Perfect day for progressive overload - increase weight or reps!";
    }
  }
  
  /// Get detailed recovery insights for user education
  RecoveryInsights getRecoveryInsights({
    required double recoveryScore,
    required RecoveryMetrics? metrics,
    required double? avgHRV,
  }) {
    if (metrics == null) {
      return RecoveryInsights(
        overallStatus: 'Unknown',
        sleepStatus: 'No data',
        hrvStatus: 'No data',
        recommendations: ['Connect Apple Health to track recovery metrics'],
      );
    }
    
    // Overall status
    String overallStatus;
    if (recoveryScore >= 85) {
      overallStatus = 'Excellent';
    } else if (recoveryScore >= 70) {
      overallStatus = 'Good';
    } else if (recoveryScore >= 50) {
      overallStatus = 'Moderate';
    } else {
      overallStatus = 'Poor';
    }
    
    // Sleep status
    String sleepStatus;
    if (metrics.sleepHours >= 8) {
      sleepStatus = 'Excellent (${metrics.sleepHours.toStringAsFixed(1)}h)';
    } else if (metrics.sleepHours >= 7) {
      sleepStatus = 'Good (${metrics.sleepHours.toStringAsFixed(1)}h)';
    } else if (metrics.sleepHours >= 6) {
      sleepStatus = 'Moderate (${metrics.sleepHours.toStringAsFixed(1)}h)';
    } else {
      sleepStatus = 'Poor (${metrics.sleepHours.toStringAsFixed(1)}h)';
    }
    
    // HRV status
    String hrvStatus;
    final hrvValue = metrics.hrv.toInt();
    if (metrics.hrv >= 70) {
      hrvStatus = 'Excellent ($hrvValue ms)';
    } else if (metrics.hrv >= 50) {
      hrvStatus = 'Good ($hrvValue ms)';
    } else if (metrics.hrv >= 30) {
      hrvStatus = 'Moderate ($hrvValue ms)';
    } else {
      hrvStatus = 'Low ($hrvValue ms)';
    }
    
    // Generate recommendations
    List<String> recommendations = [];
    
    if (metrics.sleepHours < 7) {
      recommendations.add('Prioritize 7-9 hours of sleep tonight');
    }
    
    if (metrics.hrv < 40 && avgHRV != null && metrics.hrv < avgHRV * 0.85) {
      recommendations.add('HRV is 15%+ below your average - reduce workout intensity');
    }
    
    if (metrics.restingHR > 75) {
      recommendations.add('Elevated resting heart rate - consider stress management');
    }
    
    if (recoveryScore < 60) {
      recommendations.add('Focus on nutrition: increase protein and hydration');
      recommendations.add('Consider active recovery: light walk or stretching');
    }
    
    if (recommendations.isEmpty) {
      recommendations.add('Recovery is on track - maintain current routine');
    }
    
    return RecoveryInsights(
      overallStatus: overallStatus,
      sleepStatus: sleepStatus,
      hrvStatus: hrvStatus,
      recommendations: recommendations,
    );
  }
  
  /// Adjust workout intensity based on recovery score
  /// Returns modified workout session with adjusted weights and volume
  WorkoutSession adjustWorkoutIntensity({
    required WorkoutSession plannedWorkout,
    required double recoveryScore,
  }) {
    // No adjustment needed for excellent recovery
    if (recoveryScore >= 70) {
      return plannedWorkout;
    }
    
    // Calculate intensity reduction factor
    double intensityFactor = 1.0;
    int volumeReduction = 0; // Number of sets to remove per exercise
    
    if (recoveryScore < 40) {
      // Critical - recommend complete rest
      intensityFactor = 0.0; // Effectively cancels workout
      volumeReduction = 999; // Remove all sets
    } else if (recoveryScore < 50) {
      // Low recovery - major reduction
      intensityFactor = 0.7; // 30% weight reduction
      volumeReduction = 2; // Remove 2 sets per exercise
    } else if (recoveryScore < 60) {
      // Below average - moderate reduction
      intensityFactor = 0.8; // 20% weight reduction
      volumeReduction = 1; // Remove 1 set per exercise
    } else {
      // Moderate recovery - minor adjustment
      intensityFactor = 0.9; // 10% weight reduction
      volumeReduction = 0; // Keep same volume
    }
    
    // If critical recovery, return workout with warning note
    if (intensityFactor == 0.0) {
      return plannedWorkout.copyWith(
        notes: '⚠️ WORKOUT CANCELLED - Critical recovery needed. Rest day recommended.',
      );
    }
    
    // Add note about adjustment (actual set/weight adjustments handled in UI layer)
    final adjustmentNote = recoveryScore < 50
        ? '\n⚠️ AUTO-ADJUSTED: Recovery score low ($recoveryScore/100). Recommend reducing intensity by ${((1 - intensityFactor) * 100).toInt()}% and volume by $volumeReduction set(s).'
        : '\nℹ️ ADJUSTED: Moderate recovery ($recoveryScore/100). Consider reducing intensity by ${((1 - intensityFactor) * 100).toInt()}%.';
    
    return plannedWorkout.copyWith(
      notes: (plannedWorkout.notes ?? '') + adjustmentNote,
    );
  }
  
  /// Check if user should be warned before starting workout
  bool shouldWarnBeforeWorkout(double recoveryScore) {
    return recoveryScore < 50;
  }
  
  /// Get warning message to display before workout
  String getWorkoutWarningMessage(double recoveryScore) {
    if (recoveryScore < 40) {
      return "Your recovery score is critically low ($recoveryScore/100). "
          "Your body needs rest to adapt and grow. Consider taking a rest day.";
    } else if (recoveryScore < 50) {
      return "Your recovery score is low ($recoveryScore/100). "
          "We've reduced the workout intensity. Listen to your body and stop if needed.";
    }
    return "";
  }
}

/// Data class for recovery insights
class RecoveryInsights {
  final String overallStatus;
  final String sleepStatus;
  final String hrvStatus;
  final List<String> recommendations;
  
  const RecoveryInsights({
    required this.overallStatus,
    required this.sleepStatus,
    required this.hrvStatus,
    required this.recommendations,
  });
}
