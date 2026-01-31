import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// Widget displaying sleep breakdown with visual bars
class SleepBreakdownWidget extends StatelessWidget {
  final double totalHours;
  final double? deepSleep;
  final double? remSleep;
  final double? lightSleep;
  
  const SleepBreakdownWidget({
    super.key,
    required this.totalHours,
    this.deepSleep,
    this.remSleep,
    this.lightSleep,
  });

  @override
  Widget build(BuildContext context) {
    final hasBreakdown = deepSleep != null && remSleep != null && lightSleep != null;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.borderColor,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.bedtime,
                color: AppColors.primaryGold,
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text(
                'Sleep Quality',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Total sleep time
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Sleep',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              Text(
                '${totalHours.toStringAsFixed(1)} hours',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          if (hasBreakdown) ...[
            const SizedBox(height: 20),
            _SleepPhaseBar(
              label: 'Deep Sleep',
              hours: deepSleep!,
              color: const Color(0xFF6366F1), // Indigo
              percentage: (deepSleep! / totalHours) * 100,
            ),
            const SizedBox(height: 12),
            _SleepPhaseBar(
              label: 'REM Sleep',
              hours: remSleep!,
              color: const Color(0xFFA855F7), // Purple
              percentage: (remSleep! / totalHours) * 100,
            ),
            const SizedBox(height: 12),
            _SleepPhaseBar(
              label: 'Light Sleep',
              hours: lightSleep!,
              color: const Color(0xFF3B82F6), // Blue
              percentage: (lightSleep! / totalHours) * 100,
            ),
          ] else ...[
            const SizedBox(height: 12),
            Text(
              'Sleep stage breakdown not available',
              style: TextStyle(
                color: AppColors.textSecondary.withOpacity(0.7),
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SleepPhaseBar extends StatelessWidget {
  final String label;
  final double hours;
  final Color color;
  final double percentage;
  
  const _SleepPhaseBar({
    required this.label,
    required this.hours,
    required this.color,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            Text(
              '${hours.toStringAsFixed(1)}h (${percentage.toInt()}%)',
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: AppColors.borderColor.withOpacity(0.3),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}
