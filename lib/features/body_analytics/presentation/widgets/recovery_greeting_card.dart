import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../providers/recovery_provider.dart';

/// Widget that displays a personalized greeting with recovery score
/// Shows at the top of the home screen for context-aware coaching
class RecoveryGreetingCard extends ConsumerWidget {
  const RecoveryGreetingCard({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _getEmoji(double? score) {
    if (score == null) return '👋';
    if (score >= 80) return '💪';
    if (score >= 60) return '😊';
    if (score >= 40) return '😌';
    return '⚠️';
  }

  Color _getCardColor(double? score) {
    if (score == null) return AppColors.cardBackground;
    if (score >= 80) return AppColors.primaryGreen.withOpacity(0.1);
    if (score >= 60) return AppColors.primaryGold.withOpacity(0.1);
    if (score >= 40) return Colors.orange.withOpacity(0.1);
    return Colors.red.withOpacity(0.1);
  }

  Color _getBorderColor(double? score) {
    if (score == null) return AppColors.textSecondary.withOpacity(0.2);
    if (score >= 80) return AppColors.primaryGreen.withOpacity(0.5);
    if (score >= 60) return AppColors.primaryGold.withOpacity(0.5);
    if (score >= 40) return Colors.orange.withOpacity(0.5);
    return Colors.red.withOpacity(0.5);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recoveryAsync = ref.watch(todayRecoveryScoreProvider);

    return recoveryAsync.when(
      data: (score) {
        final greeting = _getGreeting();
        final emoji = _getEmoji(score);
        final hasScore = score != null;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _getCardColor(score),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _getBorderColor(score),
              width: 2,
            ),
          ),
          child: Row(
            children: [
              // Emoji
              Text(
                emoji,
                style: const TextStyle(fontSize: 40),
              ),
              const SizedBox(width: 16),
              // Greeting text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$greeting!',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (hasScore) ...[
                      Text(
                        'Your recovery score is ${score?.round()}/100',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ] else ...[
                      Text(
                        'Sync with Apple Health to track recovery',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Arrow icon
              Icon(
                Icons.arrow_forward_ios,
                color: AppColors.textSecondary,
                size: 16,
              ),
            ],
          ),
        );
      },
      loading: () => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primaryGreen,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'Loading recovery data...',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
