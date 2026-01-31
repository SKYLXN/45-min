import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/services/firebase_exercise_service.dart';
import '../data/models/exercise.dart';

// ============================================================================
// FIREBASE SERVICE PROVIDER
// ============================================================================

/// Firebase exercise service provider
final firebaseExerciseServiceProvider = Provider<FirebaseExerciseService>((ref) {
  return FirebaseExerciseService();
});

// ============================================================================
// MAPPING PROVIDER
// ============================================================================

/// Exercise ID mapping (local ID -> Firebase name)
final exerciseMappingProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final jsonString = await rootBundle.loadString(
    'lib/features/exercise_database/data/firebase_mapping.json',
  );
  return json.decode(jsonString) as Map<String, dynamic>;
});

// ============================================================================
// VIDEO URL PROVIDER
// ============================================================================

/// Get video URL for an exercise
/// 
/// Usage: ref.watch(exerciseVideoUrlProvider('ex_001'))
final exerciseVideoUrlProvider = FutureProvider.family<String?, String>((ref, exerciseId) async {
  try {
    // Get mapping
    final mapping = await ref.watch(exerciseMappingProvider.future);
    final nameMapping = mapping['mapping'] as Map<String, dynamic>;
    final defaultVideos = mapping['default_videos'] as Map<String, dynamic>;
    
    // Find Firebase name
    final firebaseName = nameMapping[exerciseId] as String?;
    if (firebaseName == null) {
      print('⚠️ No Firebase mapping for: $exerciseId');
      return null;
    }
    
    // Get default video preferences
    final videoPrefs = defaultVideos[exerciseId] as Map<String, dynamic>?;
    final gender = videoPrefs?['gender'] as String? ?? 'male';
    final angle = videoPrefs?['angle'] as String? ?? 'front';
    
    // Fetch from Firebase
    final service = ref.read(firebaseExerciseServiceProvider);
    return await service.getExerciseVideoUrl(
      firebaseName,
      gender: gender,
      angle: angle,
    );
  } catch (e) {
    print('❌ Error fetching video URL: $e');
    return null;
  }
});

// ============================================================================
// EXERCISE VIDEOS PROVIDER
// ============================================================================

/// Get all videos for an exercise (all angles/genders)
final exerciseVideosProvider = FutureProvider.family<List<FirebaseVideo>, String>((ref, exerciseId) async {
  try {
    // Get mapping
    final mapping = await ref.watch(exerciseMappingProvider.future);
    final nameMapping = mapping['mapping'] as Map<String, dynamic>;
    
    // Find Firebase name
    final firebaseName = nameMapping[exerciseId] as String?;
    if (firebaseName == null) return [];
    
    // Fetch from Firebase
    final service = ref.read(firebaseExerciseServiceProvider);
    return await service.getExerciseVideos(firebaseName);
  } catch (e) {
    print('❌ Error fetching exercise videos: $e');
    return [];
  }
});

// ============================================================================
// FIREBASE AVAILABILITY PROVIDER
// ============================================================================

/// Check if Firebase is available
final firebaseAvailabilityProvider = FutureProvider<bool>((ref) async {
  final service = ref.read(firebaseExerciseServiceProvider);
  return await service.isAvailable();
});

// ============================================================================
// ENHANCED EXERCISE PROVIDER (with Firebase data)
// ============================================================================

/// State for enhanced exercise with Firebase data
class EnhancedExerciseState {
  final Exercise exercise;
  final List<FirebaseVideo> videos;
  final bool isLoading;
  final String? error;

  const EnhancedExerciseState({
    required this.exercise,
    this.videos = const [],
    this.isLoading = false,
    this.error,
  });

  EnhancedExerciseState copyWith({
    Exercise? exercise,
    List<FirebaseVideo>? videos,
    bool? isLoading,
    String? error,
  }) {
    return EnhancedExerciseState(
      exercise: exercise ?? this.exercise,
      videos: videos ?? this.videos,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

/// Enhanced exercise provider that combines local + Firebase data
final enhancedExerciseProvider = FutureProvider.family<EnhancedExerciseState, String>(
  (ref, exerciseId) async {
    try {
      // This would typically come from your exercise repository
      // For now, we'll just fetch the videos
      final videos = await ref.watch(exerciseVideosProvider(exerciseId).future);
      
      // You'll need to implement getting the base exercise
      // For example: final exercise = await ref.read(exerciseRepositoryProvider).getExerciseById(exerciseId);
      
      return EnhancedExerciseState(
        exercise: Exercise(
          id: exerciseId,
          name: 'Exercise $exerciseId', // Placeholder
          muscleGroup: 'Unknown',
          secondaryMuscles: [],
          equipmentRequired: [],
          difficulty: 'Intermediate',
          instructions: [],
          tempo: '3-0-1-0',
          isCompound: true,
          alternatives: [],
        ),
        videos: videos,
        isLoading: false,
      );
    } catch (e) {
      return EnhancedExerciseState(
        exercise: Exercise(
          id: exerciseId,
          name: 'Exercise $exerciseId',
          muscleGroup: 'Unknown',
          secondaryMuscles: [],
          equipmentRequired: [],
          difficulty: 'Intermediate',
          instructions: [],
          tempo: '3-0-1-0',
          isCompound: true,
          alternatives: [],
        ),
        error: e.toString(),
      );
    }
  },
);
