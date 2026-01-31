import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../../core/constants/app_colors.dart';

/// Macro Ring Chart - Animated circular progress for protein, carbs, and fats
class MacroRingChart extends StatelessWidget {
  final double targetProtein;
  final double targetCarbs;
  final double targetFats;
  final double consumedProtein;
  final double consumedCarbs;
  final double consumedFats;

  const MacroRingChart({
    super.key,
    required this.targetProtein,
    required this.targetCarbs,
    required this.targetFats,
    required this.consumedProtein,
    required this.consumedCarbs,
    required this.consumedFats,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.textSecondary.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Macros',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMacroRing(
                label: 'Protein',
                target: targetProtein,
                consumed: consumedProtein,
                color: AppColors.primaryGreen,
                unit: 'g',
              ),
              _buildMacroRing(
                label: 'Carbs',
                target: targetCarbs,
                consumed: consumedCarbs,
                color: AppColors.primaryGold,
                unit: 'g',
              ),
              _buildMacroRing(
                label: 'Fats',
                target: targetFats,
                consumed: consumedFats,
                color: AppColors.warning,
                unit: 'g',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacroRing({
    required String label,
    required double target,
    required double consumed,
    required Color color,
    required String unit,
  }) {
    final progress = target > 0 ? (consumed / target).clamp(0.0, 1.0) : 0.0;
    final isOver = consumed > target;

    return Column(
      children: [
        // Ring
        SizedBox(
          width: 90,
          height: 90,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background ring
              CustomPaint(
                size: const Size(90, 90),
                painter: _RingPainter(
                  progress: 1.0,
                  color: color.withOpacity(0.15),
                  strokeWidth: 8,
                ),
              ),
              // Progress ring
              CustomPaint(
                size: const Size(90, 90),
                painter: _RingPainter(
                  progress: progress,
                  color: isOver ? AppColors.error : color,
                  strokeWidth: 8,
                ),
              ),
              // Center text
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    consumed.toInt().toString(),
                    style: TextStyle(
                      color: isOver ? AppColors.error : AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '/ ${target.toInt()}$unit',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Label
        Text(
          label,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        // Percentage
        Text(
          '${(progress * 100).toInt()}%',
          style: TextStyle(
            color: isOver ? AppColors.error : color,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  _RingPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const startAngle = -math.pi / 2; // Start at top
    final sweepAngle = 2 * math.pi * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
