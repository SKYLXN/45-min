import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/providers/timer_provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import 'dart:math' as math;

class RestTimerOverlay extends ConsumerWidget {
  final VoidCallback onSkip;
  final Function(int) onAddTime;

  const RestTimerOverlay({
    super.key,
    required this.onSkip,
    required this.onAddTime,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timerState = ref.watch(restTimerProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark.withOpacity(0.95),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Rest Time',
                style: AppTextStyles.h2.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 40),
              
              // Circular timer
              _buildCircularTimer(timerState),
              
              const SizedBox(height: 40),
              
              // Timer controls
              _buildTimerControls(ref),
              
              const SizedBox(height: 32),
              
              // Skip button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: onSkip,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Skip Rest',
                    style: AppTextStyles.button.copyWith(
                      color: AppColors.backgroundDark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              Text(
                'Get ready for the next set!',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCircularTimer(RestTimerState state) {
    return SizedBox(
      width: 220,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background circle
          CustomPaint(
            size: const Size(220, 220),
            painter: CircularTimerPainter(
              progress: state.progress,
              backgroundColor: AppColors.cardBackground,
              progressColor: AppColors.primaryGold,
            ),
          ),
          
          // Time text
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                state.formattedTime,
                style: AppTextStyles.display.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 56,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'remaining',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimerControls(WidgetRef ref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildTimeButton(
          label: '-15s',
          icon: Icons.remove,
          onPressed: () => onAddTime(-15),
        ),
        const SizedBox(width: 16),
        _buildPauseButton(ref),
        const SizedBox(width: 16),
        _buildTimeButton(
          label: '+15s',
          icon: Icons.add,
          onPressed: () => onAddTime(15),
        ),
      ],
    );
  }

  Widget _buildTimeButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        side: BorderSide(color: AppColors.textSecondary.withOpacity(0.3)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    );
  }

  Widget _buildPauseButton(WidgetRef ref) {
    final timerState = ref.watch(restTimerProvider);
    final timerNotifier = ref.read(restTimerProvider.notifier);

    return IconButton(
      onPressed: () {
        if (timerState.isPaused) {
          timerNotifier.resume();
        } else {
          timerNotifier.pause();
        }
      },
      icon: Icon(
        timerState.isPaused ? Icons.play_arrow : Icons.pause,
        size: 32,
      ),
      color: AppColors.primaryGold,
    );
  }
}

class CircularTimerPainter extends CustomPainter {
  final double progress;
  final Color backgroundColor;
  final Color progressColor;

  CircularTimerPainter({
    required this.progress,
    required this.backgroundColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw background circle
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius - 6, backgroundPaint);

    // Draw progress arc
    final progressPaint = Paint()
      ..color = progressColor
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 6),
      -math.pi / 2, // Start from top
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(CircularTimerPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
