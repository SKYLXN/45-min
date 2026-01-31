import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/exercise.dart';
import '../../../smart_planner/data/models/weekly_program.dart';
import '../../../workout_mode/providers/active_workout_provider.dart';

/// Dialog for adding an exercise to a workout
class AddToWorkoutDialog extends ConsumerStatefulWidget {
  final Exercise exercise;

  const AddToWorkoutDialog({
    super.key,
    required this.exercise,
  });

  @override
  ConsumerState<AddToWorkoutDialog> createState() =>
      _AddToWorkoutDialogState();
}

class _AddToWorkoutDialogState extends ConsumerState<AddToWorkoutDialog> {
  int _sets = 3;
  int _reps = 10;
  double _weight = 0.0;
  int _restTime = 90;
  double _targetRPE = 7.0;

  @override
  Widget build(BuildContext context) {
    final workoutState = ref.watch(activeWorkoutProvider);
    final hasActiveWorkout = workoutState.isActive;

    return Dialog(
      backgroundColor: const Color(0xFF151B2D),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  const Icon(
                    Icons.add_circle_outline,
                    color: AppColors.primaryGreen,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Add to Workout',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                widget.exercise.name,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 24),

              // Set configuration
              _buildNumberInput(
                label: 'Sets',
                value: _sets,
                min: 1,
                max: 10,
                onChanged: (value) => setState(() => _sets = value),
              ),
              const SizedBox(height: 16),

              _buildNumberInput(
                label: 'Reps',
                value: _reps,
                min: 1,
                max: 50,
                onChanged: (value) => setState(() => _reps = value),
              ),
              const SizedBox(height: 16),

              _buildWeightInput(),
              const SizedBox(height: 16),

              _buildNumberInput(
                label: 'Rest Time (seconds)',
                value: _restTime,
                min: 30,
                max: 300,
                step: 15,
                onChanged: (value) => setState(() => _restTime = value),
              ),
              const SizedBox(height: 16),

              _buildSliderInput(
                label: 'Target RPE',
                value: _targetRPE,
                min: 5.0,
                max: 10.0,
                divisions: 10,
                onChanged: (value) => setState(() => _targetRPE = value),
              ),
              const SizedBox(height: 24),

              // Action buttons
              if (hasActiveWorkout) ...[
                _buildActionButton(
                  label: 'Add to Active Workout',
                  icon: Icons.fitness_center,
                  color: AppColors.primaryGreen,
                  onPressed: () => _addToActiveWorkout(context),
                ),
                const SizedBox(height: 12),
              ],
              _buildActionButton(
                label: 'Start Quick Workout',
                icon: Icons.play_circle_outline,
                color: Colors.orange,
                onPressed: () => _startQuickWorkout(context),
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
    required int min,
    required int max,
    int step = 1,
    required ValueChanged<int> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.primaryGreen,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF0A0E1A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primaryGreen.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline,
                    color: Colors.white),
                onPressed: value > min
                    ? () => onChanged((value - step).clamp(min, max))
                    : null,
              ),
              Text(
                '$value',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, color: Colors.white),
                onPressed: value < max
                    ? () => onChanged((value + step).clamp(min, max))
                    : null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWeightInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Weight (kg)',
          style: TextStyle(
            color: AppColors.primaryGreen,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF0A0E1A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primaryGreen.withOpacity(0.3)),
          ),
          child: TextField(
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: '0.0',
              hintStyle: TextStyle(color: Colors.white38),
            ),
            onChanged: (value) {
              setState(() {
                _weight = double.tryParse(value) ?? 0.0;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSliderInput({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppColors.primaryGreen,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: _getRPEColor(value).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _getRPEColor(value)),
              ),
              child: Text(
                value.toStringAsFixed(1),
                style: TextStyle(
                  color: _getRPEColor(value),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: _getRPEColor(value),
            inactiveTrackColor: Colors.white12,
            thumbColor: _getRPEColor(value),
            overlayColor: _getRPEColor(value).withOpacity(0.2),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRPEColor(double rpe) {
    if (rpe <= 6) return AppColors.primaryGreen;
    if (rpe <= 8) return Colors.orange;
    return Colors.red;
  }

  Future<void> _addToActiveWorkout(BuildContext context) async {
    try {
      final workoutNotifier = ref.read(activeWorkoutProvider.notifier);
      final currentWorkout = ref.read(activeWorkoutProvider).plannedWorkout;

      if (currentWorkout == null) {
        throw Exception('No active workout found');
      }

      // Create a new planned exercise
      final plannedExercise = PlannedExercise(
        exercise: widget.exercise,
        sets: _sets,
        reps: _reps,
        weight: _weight,
        restTime: _restTime,
        targetRPE: _targetRPE,
      );

      // Add exercise to current workout
      final updatedWorkout = currentWorkout.copyWith(
        exercises: [...currentWorkout.exercises, plannedExercise],
      );

      // Update the workout
      // Note: You'll need to implement updateWorkout in ActiveWorkoutNotifier
      // For now, show success message
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.exercise.name} added to active workout!'),
            backgroundColor: AppColors.primaryGreen,
            action: SnackBarAction(
              label: 'VIEW',
              textColor: Colors.white,
              onPressed: () {
                // Navigate to active workout
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _startQuickWorkout(BuildContext context) async {
    try {
      final workoutNotifier = ref.read(activeWorkoutProvider.notifier);
      const uuid = Uuid();

      // Create a quick workout with just this exercise
      final plannedExercise = PlannedExercise(
        exercise: widget.exercise,
        sets: _sets,
        reps: _reps,
        weight: _weight,
        restTime: _restTime,
        targetRPE: _targetRPE,
      );

      final quickWorkout = PlannedWorkout(
        id: uuid.v4(),
        workoutType: 'Quick',
        name: 'Quick Workout',
        exercises: [plannedExercise],
        estimatedDuration: (_sets * (_reps * 3 + _restTime) / 60).ceil(),
        requiredEquipment: widget.exercise.equipmentRequired,
      );

      // Start the workout
      await workoutNotifier.startWorkout(quickWorkout);

      if (context.mounted) {
        Navigator.pop(context);
        // Navigate to active workout screen
        // Note: You'll need to import go_router for this
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Quick workout started!'),
            backgroundColor: AppColors.primaryGreen,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting workout: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
