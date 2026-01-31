import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../../core/constants/app_colors.dart';

/// Circular progress widget displaying recovery score (0-100)
/// with color-coded status and animated progress
class RecoveryScoreWidget extends StatelessWidget {
  final double? score;
  final bool isLoading;
  final double size;
  
  const RecoveryScoreWidget({
    super.key,
    this.score,
    this.isLoading = false,
    this.size = 200,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      child: isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.primaryGreen,
                ),
              ),
            )
          : score == null
              ? _buildNoData()
              : _buildScoreDisplay(),
    );
  }
  
  Widget _buildNoData() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.favorite_border,
            size: size * 0.3,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 8),
          Text(
            'No Data',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: size * 0.08,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildScoreDisplay() {
    final scoreValue = score!.clamp(0.0, 100.0);
    final color = _getScoreColor(scoreValue);
    final status = _getScoreStatus(scoreValue);
    
    return Stack(
      alignment: Alignment.center,
      children: [
        // Background circle
        CustomPaint(
          size: Size(size, size),
          painter: _CircularProgressPainter(
            progress: 1.0,
            color: AppColors.borderColor.withOpacity(0.2),
            strokeWidth: size * 0.08,
          ),
        ),
        // Progress circle
        CustomPaint(
          size: Size(size, size),
          painter: _CircularProgressPainter(
            progress: scoreValue / 100,
            color: color,
            strokeWidth: size * 0.08,
          ),
        ),
        // Score text
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              scoreValue.toInt().toString(),
              style: TextStyle(
                color: color,
                fontSize: size * 0.25,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              status,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: size * 0.08,
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Color _getScoreColor(double score) {
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
  
  String _getScoreStatus(double score) {
    if (score >= 85) {
      return 'Excellent';
    } else if (score >= 70) {
      return 'Good';
    } else if (score >= 50) {
      return 'Moderate';
    } else {
      return 'Poor';
    }
  }
}

/// Custom painter for circular progress indicator
class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;
  
  _CircularProgressPainter({
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
    
    const startAngle = -math.pi / 2;
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
  bool shouldRepaint(_CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
