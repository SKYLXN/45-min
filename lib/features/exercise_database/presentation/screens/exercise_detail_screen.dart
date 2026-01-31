import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/exercise.dart';
import '../../data/repositories/exercise_repository.dart';
import '../widgets/muscle_tag.dart';
import '../widgets/smart_video_player.dart';
import '../widgets/add_to_workout_dialog.dart';

/// Detailed view of a single exercise
class ExerciseDetailScreen extends ConsumerWidget {
  final Exercise exercise;

  const ExerciseDetailScreen({
    super.key,
    required this.exercise,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Debug: Check Firebase IDs
    print('📋 ExerciseDetailScreen for: ${exercise.name}');
    print('   firebaseId: ${exercise.firebaseId}');
    print('   firebaseName: ${exercise.firebaseName}');
    
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: CustomScrollView(
        slivers: [
          // App bar with video/gif
          SliverAppBar(
            backgroundColor: const Color(0xFF151B2D),
            expandedHeight: 300,
            pinned: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: (exercise.firebaseId != null || exercise.firebaseName != null)
                  ? SmartVideoPlayer(
                      firebaseExerciseId: exercise.firebaseId,
                      firebaseExerciseName: exercise.firebaseName,
                      gender: 'male',
                      angle: 'front',
                    )
                  : Container(
                      color: const Color(0xFF151B2D),
                      child: const Center(
                        child: Icon(
                          Icons.fitness_center,
                          size: 80,
                          color: Colors.white24,
                        ),
                      ),
                    ),
            ),
          ),

          // Exercise details
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Exercise name and tags
                  Text(
                    exercise.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Tags row
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      MuscleTag(muscleGroup: exercise.muscleGroup),
                      _buildInfoChip(
                        exercise.difficulty,
                        _getDifficultyColor(exercise.difficulty),
                      ),
                      if (exercise.isCompound)
                        _buildInfoChip('Compound', const Color(0xFF00FF88)),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Target muscles section
                  _buildSectionHeader('Target Muscles'),
                  const SizedBox(height: 12),
                  _buildMusclesList(),
                  const SizedBox(height: 24),

                  // Equipment section
                  _buildSectionHeader('Equipment Required'),
                  const SizedBox(height: 12),
                  _buildEquipmentList(),
                  const SizedBox(height: 24),

                  // Tempo section
                  _buildSectionHeader('Tempo'),
                  const SizedBox(height: 12),
                  _buildTempoIndicator(),
                  const SizedBox(height: 24),

                  // Instructions section
                  _buildSectionHeader('Instructions'),
                  const SizedBox(height: 12),
                  _buildInstructionsList(),
                  const SizedBox(height: 24),

                  // Alternative exercises
                  if (exercise.alternatives.isNotEmpty) ...[
                    _buildSectionHeader('Alternative Exercises'),
                    const SizedBox(height: 12),
                    _buildAlternativeExercises(ref),
                    const SizedBox(height: 24),
                  ],

                  // Action buttons
                  _buildActionButtons(context),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Color(0xFF00FF88),
        fontSize: 18,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildInfoChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildMusclesList() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF151B2D),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.fitness_center,
                color: Color(0xFF00FF88),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Primary: ${exercise.muscleGroup}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (exercise.secondaryMuscles.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.add_circle_outline,
                  color: Color(0xFFB0B8C8),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Secondary: ${exercise.secondaryMuscles.join(', ')}',
                    style: const TextStyle(
                      color: Color(0xFFB0B8C8),
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEquipmentList() {
    if (exercise.equipmentRequired.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF151B2D),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          children: [
            Icon(
              Icons.accessibility_new,
              color: Color(0xFF00FF88),
              size: 20,
            ),
            SizedBox(width: 8),
            Text(
              'Bodyweight Only',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: exercise.equipmentRequired.map((equipment) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF151B2D),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.construction,
                color: Color(0xFFFFD700),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                equipment,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTempoIndicator() {
    final components = exercise.tempoComponents;
    final labels = ['Eccentric', 'Pause', 'Concentric', 'Pause'];
    final tut = exercise.timeUnderTension;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF151B2D),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(4, (index) {
              return Column(
                children: [
                  Text(
                    labels[index],
                    style: const TextStyle(
                      color: Color(0xFFB0B8C8),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A0E1A),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF00FF88),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '${components[index]}s',
                        style: const TextStyle(
                          color: Color(0xFF00FF88),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }),
          ),
          const SizedBox(height: 16),
          Text(
            'Total Time Under Tension: ${tut}s per rep',
            style: const TextStyle(
              color: Color(0xFFFFD700),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionsList() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF151B2D),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: List.generate(exercise.instructions.length, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00FF88).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Color(0xFF00FF88),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    exercise.instructions[index],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildAlternativeExercises(WidgetRef ref) {
    final repository = ExerciseRepository();

    return FutureBuilder<List<Exercise>>(
      future: _fetchAlternatives(repository),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF00FF88)),
          );
        }

        final alternatives = snapshot.data ?? [];
        if (alternatives.isEmpty) {
          return const SizedBox.shrink();
        }

        return SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: alternatives.length,
            itemBuilder: (context, index) {
              final alt = alternatives[index];
              return GestureDetector(
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ExerciseDetailScreen(exercise: alt),
                    ),
                  );
                },
                child: Container(
                  width: 200,
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF151B2D),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        alt.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      MuscleTag(muscleGroup: alt.muscleGroup, small: true),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<List<Exercise>> _fetchAlternatives(ExerciseRepository repository) async {
    final futures = exercise.alternatives.map((id) => repository.getExerciseById(id));
    final results = await Future.wait(futures);
    return results.whereType<Exercise>().toList();
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AddToWorkoutDialog(exercise: exercise),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00FF88),
              foregroundColor: const Color(0xFF0A0E1A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_circle_outline, size: 24),
                SizedBox(width: 8),
                Text(
                  'Add to Workout',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton(
            onPressed: () {
              if (exercise.firebaseId != null || exercise.firebaseName != null) {
                _openFullscreenVideo(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('No video available for this exercise'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF00FF88), width: 2),
              foregroundColor: const Color(0xFF00FF88),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.play_circle_outline, size: 24),
                SizedBox(width: 8),
                Text(
                  'Watch Full Video',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _openFullscreenVideo(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              exercise.name,
              style: const TextStyle(color: Colors.white),
            ),
          ),
          body: Center(
            child: SmartVideoPlayer(
              firebaseExerciseId: exercise.firebaseId,
              firebaseExerciseName: exercise.firebaseName,
              gender: 'male',
              angle: 'front',
            ),
          ),
        ),
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        return const Color(0xFF00FF88);
      case 'intermediate':
        return const Color(0xFFFFD700);
      case 'advanced':
        return Colors.red;
      default:
        return const Color(0xFFB0B8C8);
    }
  }
}
