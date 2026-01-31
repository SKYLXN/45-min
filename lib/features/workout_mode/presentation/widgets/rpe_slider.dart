import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class RPESlider extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const RPESlider({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // RPE value display
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: _getGradientForRPE(value),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$value',
                style: AppTextStyles.display.copyWith(
                  color: AppColors.backgroundDark,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '/ 10',
                style: AppTextStyles.h3.copyWith(
                  color: AppColors.backgroundDark.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // RPE description
        Text(
          _getRPEDescription(value),
          style: AppTextStyles.body.copyWith(
            color: _getColorForRPE(value),
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 16),

        // Slider
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: _getColorForRPE(value),
            inactiveTrackColor: AppColors.cardBackground,
            thumbColor: _getColorForRPE(value),
            overlayColor: _getColorForRPE(value).withOpacity(0.2),
            trackHeight: 8,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 24),
          ),
          child: Slider(
            value: value.toDouble(),
            min: 1,
            max: 10,
            divisions: 9,
            onChanged: (newValue) => onChanged(newValue.round()),
          ),
        ),

        // RPE scale reference
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(10, (index) {
              final rpeValue = index + 1;
              return Text(
                '$rpeValue',
                style: AppTextStyles.caption.copyWith(
                  color: value == rpeValue
                      ? _getColorForRPE(rpeValue)
                      : AppColors.textSecondary.withOpacity(0.5),
                  fontWeight: value == rpeValue ? FontWeight.bold : FontWeight.normal,
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Color _getColorForRPE(int rpe) {
    if (rpe <= 3) return Colors.green;
    if (rpe <= 5) return Colors.lightGreen;
    if (rpe <= 7) return AppColors.primaryGold;
    if (rpe <= 8) return Colors.orange;
    return Colors.red;
  }

  LinearGradient _getGradientForRPE(int rpe) {
    final color = _getColorForRPE(rpe);
    return LinearGradient(
      colors: [color, color.withOpacity(0.7)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  String _getRPEDescription(int rpe) {
    switch (rpe) {
      case 1:
      case 2:
        return 'Very Easy - Could do many more reps';
      case 3:
      case 4:
        return 'Easy - Could do 5-6 more reps';
      case 5:
      case 6:
        return 'Moderate - Could do 3-4 more reps';
      case 7:
        return 'Challenging - Could do 2-3 more reps';
      case 8:
        return 'Hard - Could do 1-2 more reps';
      case 9:
        return 'Very Hard - Could do 1 more rep';
      case 10:
        return 'Maximum Effort - Absolute limit!';
      default:
        return '';
    }
  }
}
