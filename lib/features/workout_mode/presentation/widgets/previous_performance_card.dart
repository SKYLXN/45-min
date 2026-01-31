import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class PreviousPerformanceCard extends StatelessWidget {
  final double? previousWeight;
  final double? previousRPE;
  final int targetReps;

  const PreviousPerformanceCard({
    super.key,
    this.previousWeight,
    this.previousRPE,
    required this.targetReps,
  });

  @override
  Widget build(BuildContext context) {
    if (previousWeight == null && previousRPE == null) {
      return _buildFirstTimeCard();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primaryGold.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.history,
                size: 18,
                color: AppColors.primaryGold,
              ),
              const SizedBox(width: 8),
              Text(
                'Previous Performance',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (previousWeight != null) ...[
                Expanded(
                  child: _buildStatBox(
                    'Last Weight',
                    '${previousWeight!.toStringAsFixed(1)} kg',
                    Icons.fitness_center,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: _buildStatBox(
                  'Target Reps',
                  '$targetReps',
                  Icons.repeat,
                ),
              ),
              if (previousRPE != null) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatBox(
                    'Last RPE',
                    previousRPE!.toStringAsFixed(1),
                    Icons.speed,
                  ),
                ),
              ],
            ],
          ),
          if (previousWeight != null && previousRPE != null) ...[
            const SizedBox(height: 12),
            _buildRecommendation(),
          ],
        ],
      ),
    );
  }

  Widget _buildFirstTimeCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primaryGreen.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.celebration,
            color: AppColors.primaryGreen,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'First time doing this exercise! Start with a comfortable weight.',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundDark,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.h3.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendation() {
    String message;
    Color color;
    IconData icon;

    if (previousRPE! < 7.0) {
      message = 'Try increasing weight by 2-2.5kg';
      color = AppColors.primaryGreen;
      icon = Icons.trending_up;
    } else if (previousRPE! > 9.0) {
      message = 'Consider reducing weight by 5%';
      color = AppColors.warning;
      icon = Icons.trending_down;
    } else {
      message = 'Aim to match or beat last performance';
      color = AppColors.primaryGold;
      icon = Icons.emoji_events; // Trophy icon instead of target
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.caption.copyWith(
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
