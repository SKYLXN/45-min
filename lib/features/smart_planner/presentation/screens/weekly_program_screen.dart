import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../providers/smart_planner_provider.dart';
import '../../providers/equipment_provider.dart';
import '../widgets/workout_card.dart';
import '../widgets/program_generation_loading.dart';

class WeeklyProgramScreen extends ConsumerWidget {
  const WeeklyProgramScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plannerState = ref.watch(smartPlannerProvider);
    final equipmentState = ref.watch(equipmentProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.go('/'),
        ),
        title: const Text(
          'Smart Planner',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: AppColors.textPrimary),
            onPressed: () => context.push('/equipment-setup'),
          ),
        ],
      ),
      body: plannerState.isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
              ),
            )
          : plannerState.isGenerating
              ? const ProgramGenerationLoading()
              : _buildContent(context, ref, plannerState, equipmentState),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    SmartPlannerState plannerState,
    EquipmentState equipmentState,
  ) {
    // Check if equipment is set up
    if (equipmentState.userEquipment.isEmpty ||
        equipmentState.userEquipment.where((e) => e.isAvailable).isEmpty) {
      return _buildEquipmentSetupPrompt(context);
    }

    // Check if program exists
    if (plannerState.currentProgram == null) {
      return _buildGenerateProgramPrompt(context, ref);
    }

    return _buildProgramView(context, ref, plannerState);
  }

  Widget _buildEquipmentSetupPrompt(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.fitness_center,
                size: 60,
                color: AppColors.primaryGreen,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Equipment Setup Required',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Tell us what equipment you have access to so we can create the perfect workout program for you.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => context.push('/equipment-setup'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Set Up Equipment',
                style: TextStyle(
                  color: AppColors.backgroundDark,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenerateProgramPrompt(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome,
                size: 60,
                color: AppColors.backgroundDark,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Ready to Start Training?',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Generate your personalized workout program with progressive overload and recovery-based adjustments.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () =>
                  ref.read(smartPlannerProvider.notifier).generateProgram(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Generate My Program',
                style: TextStyle(
                  color: AppColors.backgroundDark,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgramView(
    BuildContext context,
    WidgetRef ref,
    SmartPlannerState plannerState,
  ) {
    final program = plannerState.currentProgram!;
    final completionPercentage = ref.read(programCompletionProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Week indicator
          _buildWeekHeader(plannerState.currentWeek, completionPercentage),
          const SizedBox(height: 24),

          // Progression notes (if available)
          if (program.progressionNotes != null && program.progressionNotes!.isNotEmpty) ...[
            _buildProgressionNotes(program.progressionNotes!),
            const SizedBox(height: 24),
          ],

          // Workout cards
          ...program.workouts.asMap().entries.map((entry) {
            final index = entry.key;
            final workout = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: WorkoutCard(
                workout: workout,
                dayLabel: _getDayLabel(index),
                onTap: () => _navigateToWorkoutPreview(context, workout.id),
                onStartWorkout: () => _startWorkout(context, workout.id),
              ),
            );
          }).toList(),

          const SizedBox(height: 24),

          // Generate next week button
          if (completionPercentage >= 75)
            _buildGenerateNextWeekButton(context, ref),
        ],
      ),
    );
  }

  Widget _buildWeekHeader(int weekNumber, double completionPercentage) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Week $weekNumber',
                style: const TextStyle(
                  color: AppColors.backgroundDark,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.backgroundDark.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${completionPercentage.toInt()}% Complete',
                  style: const TextStyle(
                    color: AppColors.backgroundDark,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: completionPercentage / 100,
              backgroundColor: AppColors.backgroundDark.withOpacity(0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.backgroundDark,
              ),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressionNotes(String notes) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primaryGreen.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.lightbulb_outline,
            color: AppColors.primaryGold,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              notes,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenerateNextWeekButton(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () =>
            ref.read(smartPlannerProvider.notifier).generateNextWeek(),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: const BorderSide(color: AppColors.primaryGreen, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Generate Next Week',
          style: TextStyle(
            color: AppColors.primaryGreen,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  String _getDayLabel(int index) {
    const days = ['Monday', 'Wednesday', 'Friday', 'Saturday'];
    return days[index % days.length];
  }

  void _navigateToWorkoutPreview(BuildContext context, String workoutId) {
    context.push('/workout-preview/$workoutId');
  }

  void _startWorkout(BuildContext context, String workoutId) {
    context.go('/workout-preview/$workoutId');
  }
}
