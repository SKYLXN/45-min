import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/timer_provider.dart';
import '../../../../core/services/tempo_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class TempoIndicator extends ConsumerWidget {
  final String tempo;
  final int reps;
  final bool autoStart;

  const TempoIndicator({
    super.key,
    required this.tempo,
    required this.reps,
    this.autoStart = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tempoState = ref.watch(tempoTimerProvider);
    final tempoNotifier = ref.read(tempoTimerProvider.notifier);

    // Auto-start if requested and not already active
    if (autoStart && !tempoState.isActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        tempoNotifier.startTempo(tempo: tempo, reps: reps);
      });
    }

    final (ecc, bPause, con, tPause) = TempoService.parseTempo(tempo);
    final totalTUT = TempoService.calculateSetTimeUnderTension(tempo, reps);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
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
                Icons.music_note,
                color: AppColors.primaryGold,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Tempo Guidance',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              if (!tempoState.isActive)
                TextButton.icon(
                  onPressed: () => tempoNotifier.startTempo(tempo: tempo, reps: reps),
                  icon: const Icon(Icons.play_arrow, size: 18),
                  label: const Text('Start'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primaryGold,
                  ),
                )
              else
                IconButton(
                  onPressed: () => tempoNotifier.stop(),
                  icon: const Icon(Icons.stop),
                  color: AppColors.error,
                  iconSize: 20,
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Tempo breakdown
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTempoPhase('⬇️', '$ecc', 'Down', TempoPhase.eccentric, tempoState),
              _buildTempoPhase('⏸️', '$bPause', 'Pause', TempoPhase.bottomPause, tempoState),
              _buildTempoPhase('⬆️', '$con', 'Up', TempoPhase.concentric, tempoState),
              _buildTempoPhase('⏸️', '$tPause', 'Pause', TempoPhase.topPause, tempoState),
            ],
          ),

          if (tempoState.isActive) ...[
            const SizedBox(height: 16),
            _buildActiveTempoDisplay(tempoState),
          ],

          const SizedBox(height: 12),

          // Total time under tension
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.backgroundDark,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Time Under Tension',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  '${totalTUT}s',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.primaryGold,
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

  Widget _buildTempoPhase(
    String emoji,
    String duration,
    String label,
    TempoPhase phase,
    TempoTimerState state,
  ) {
    final isActive = state.isActive && state.currentBeat?.phase == phase;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.primaryGold.withOpacity(0.3)
            : AppColors.backgroundDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive
              ? AppColors.primaryGold
              : AppColors.textSecondary.withOpacity(0.3),
          width: isActive ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(height: 4),
          Text(
            '${duration}s',
            style: AppTextStyles.h3.copyWith(
              color: isActive ? AppColors.primaryGold : AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveTempoDisplay(TempoTimerState state) {
    final beat = state.currentBeat;
    if (beat == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryGold.withOpacity(0.3),
            AppColors.primaryGold.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${beat.phaseEmoji} ${beat.phaseName}',
                style: AppTextStyles.h3.copyWith(
                  color: AppColors.primaryGold,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Rep ${beat.currentRep}/${state.totalReps}',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: beat.progress,
              backgroundColor: AppColors.backgroundDark,
              valueColor: const AlwaysStoppedAnimation(AppColors.primaryGold),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${beat.secondsInPhase}s / ${beat.totalSecondsInPhase}s',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
