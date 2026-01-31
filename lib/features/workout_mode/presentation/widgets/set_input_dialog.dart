import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import 'rpe_slider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class SetInputDialog extends StatefulWidget {
  final int targetReps;
  final double targetWeight;
  final double targetRPE;
  final Function(int reps, double weight, int rpe, String? notes) onComplete;

  const SetInputDialog({
    super.key,
    required this.targetReps,
    required this.targetWeight,
    required this.targetRPE,
    required this.onComplete,
  });

  @override
  State<SetInputDialog> createState() => _SetInputDialogState();
}

class _SetInputDialogState extends State<SetInputDialog> {
  late int _reps;
  late double _weight;
  late int _rpe;
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _reps = widget.targetReps;
    _weight = widget.targetWeight;
    _rpe = widget.targetRPE.round();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.backgroundDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Complete Set',
                      style: AppTextStyles.h2.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Reps input
              _buildNumberInput(
                label: 'Reps Completed',
                value: _reps,
                onChanged: (value) => setState(() => _reps = value),
                min: 0,
                max: 50,
              ),

              const SizedBox(height: 20),

              // Weight input
              _buildWeightInput(),

              const SizedBox(height: 24),

              // RPE slider
              Text(
                'Rate of Perceived Exertion (RPE)',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              RPESlider(
                value: _rpe,
                onChanged: (value) => setState(() => _rpe = value),
              ),

              const SizedBox(height: 24),

              // Notes (optional)
              TextField(
                controller: _notesController,
                style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Notes (optional)',
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                  hintText: 'How did it feel?',
                  hintStyle: TextStyle(color: AppColors.textSecondary.withOpacity(0.5)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.textSecondary.withOpacity(0.3)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.textSecondary.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primaryGreen, width: 2),
                  ),
                ),
                maxLines: 2,
              ),

              const SizedBox(height: 24),

              // Complete button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _handleComplete,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Complete Set',
                    style: AppTextStyles.button.copyWith(
                      color: AppColors.backgroundDark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNumberInput({
    required String label,
    required int value,
    required Function(int) onChanged,
    required int min,
    required int max,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.body.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildCounterButton(
              icon: Icons.remove,
              onPressed: value > min ? () => onChanged(value - 1) : null,
            ),
            Expanded(
              child: Container(
                height: 56,
                alignment: Alignment.center,
                child: Text(
                  '$value',
                  style: AppTextStyles.h1.copyWith(
                    color: AppColors.primaryGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            _buildCounterButton(
              icon: Icons.add,
              onPressed: value < max ? () => onChanged(value + 1) : null,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWeightInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Weight (kg)',
          style: AppTextStyles.body.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildWeightButton('-2.5', () => setState(() => _weight = (_weight - 2.5).clamp(0, 500))),
            const SizedBox(width: 8),
            _buildWeightButton('-1', () => setState(() => _weight = (_weight - 1).clamp(0, 500))),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primaryGreen.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  '${_weight.toStringAsFixed(1)} kg',
                  style: AppTextStyles.h2.copyWith(
                    color: AppColors.primaryGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            _buildWeightButton('+1', () => setState(() => _weight = (_weight + 1).clamp(0, 500))),
            const SizedBox(width: 8),
            _buildWeightButton('+2.5', () => setState(() => _weight = (_weight + 2.5).clamp(0, 500))),
          ],
        ),
      ],
    );
  }

  Widget _buildCounterButton({
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.textSecondary.withOpacity(0.3),
        ),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon),
        color: onPressed != null ? AppColors.textPrimary : AppColors.textSecondary.withOpacity(0.3),
      ),
    );
  }

  Widget _buildWeightButton(String label, VoidCallback onPressed) {
    return SizedBox(
      width: 52,
      height: 56,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: BorderSide(color: AppColors.textSecondary.withOpacity(0.3)),
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.body.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  void _handleComplete() {
    final notes = _notesController.text.trim();
    widget.onComplete(
      _reps,
      _weight,
      _rpe,
      notes.isEmpty ? null : notes,
    );
  }
}
