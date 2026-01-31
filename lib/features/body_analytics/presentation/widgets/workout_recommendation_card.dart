import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// Card displaying smart workout recommendations based on recovery score
class WorkoutRecommendationCard extends StatelessWidget {
  final String recommendation;
  final double? recoveryScore;
  final VoidCallback? onViewDetails;
  
  const WorkoutRecommendationCard({
    super.key,
    required this.recommendation,
    this.recoveryScore,
    this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getRecommendationColor();
    final icon = _getRecommendationIcon();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Today\'s Recommendation',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            recommendation,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              height: 1.5,
            ),
          ),
          if (onViewDetails != null) ...[
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: onViewDetails,
              icon: const Icon(Icons.insights),
              label: const Text('View Recovery Details'),
              style: TextButton.styleFrom(
                foregroundColor: color,
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Color _getRecommendationColor() {
    if (recoveryScore == null) return AppColors.primaryGreen;
    
    if (recoveryScore! >= 85) {
      return AppColors.success;
    } else if (recoveryScore! >= 70) {
      return AppColors.primaryGreen;
    } else if (recoveryScore! >= 50) {
      return AppColors.primaryGold;
    } else {
      return AppColors.error;
    }
  }
  
  IconData _getRecommendationIcon() {
    if (recoveryScore == null) return Icons.fitness_center;
    
    if (recoveryScore! >= 85) {
      return Icons.rocket_launch;
    } else if (recoveryScore! >= 70) {
      return Icons.thumb_up;
    } else if (recoveryScore! >= 50) {
      return Icons.info_outline;
    } else {
      return Icons.warning_rounded;
    }
  }
}
